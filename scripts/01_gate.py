#!/usr/bin/env python3
"""Stage 1 — Gate candidates via the GitHub API (deterministic, no agents).
For each candidate: fetch repo metadata + languages, apply exclusion rules, record decision.
Outputs: data/01_repos_meta.jsonl (all candidates + decision), data/01_included.json (keep set).
Resumable: skips candidates already present in the meta JSONL.
"""
import json, os, subprocess, time, sys, datetime, re

CAND = "data/00_candidates.json"
META = "data/01_repos_meta.jsonl"
INCL = "data/01_included.json"
CUTOFF = "2024-06-07"          # 2 years before today (2026-06-07)

_RATE_LIMIT_PHRASES = ("rate limit", "secondary rate limit", "api rate limit exceeded")
_BACKOFF_SCHEDULE = [30, 60, 120, 300, 300]   # seconds; up to 5 retries

def _is_rate_limited(status, body, stderr, headers_text):
    """Return True if this response looks like a rate-limit (403/429 or body/stderr hint)."""
    if status in (403, 429):
        return True
    combined = (body + stderr + headers_text).lower()
    return any(phrase in combined for phrase in _RATE_LIMIT_PHRASES)

def _parse_retry_after(headers_text):
    """Extract sleep seconds from Retry-After or x-ratelimit-reset headers, or None."""
    # Retry-After: <seconds>
    m = re.search(r"(?i)^retry-after:\s*(\d+)", headers_text, re.MULTILINE)
    if m:
        return int(m.group(1)) + 2
    # x-ratelimit-reset: <epoch>
    m = re.search(r"(?i)^x-ratelimit-reset:\s*(\d+)", headers_text, re.MULTILINE)
    if m:
        reset_epoch = int(m.group(1))
        wait = max(0, reset_epoch - int(time.time())) + 5
        return wait
    return None

def gh_api(path):
    """Return (ok, json_or_none, http_status).
    Follows renames; handles 404.
    On rate-limit (403/429 or body hint): sleeps with bounded exponential backoff
    and retries up to len(_BACKOFF_SCHEDULE) times.
    After exhausting retries returns (False, None, 429) — a DISTINCT signal so
    callers can record reason="ratelimited" instead of "dead_or_renamed".
    """
    # next_sleep carries the wait to apply BEFORE the upcoming attempt (0 for the first).
    next_sleep = 0
    for attempt in range(len(_BACKOFF_SCHEDULE) + 1):
        if next_sleep:
            print(f"  [rate-limit] sleeping {next_sleep}s before retry {attempt}/{len(_BACKOFF_SCHEDULE)} for {path}", flush=True)
            time.sleep(next_sleep)
        r = subprocess.run(["gh","api","-i",path], capture_output=True, text=True)
        out = r.stdout
        # parse status line
        status = 0
        if out.startswith("HTTP/"):
            try: status = int(out.split("\n",1)[0].split()[1])
            except: status = 0
        # split headers from body (gh -i uses \r\n\r\n separator)
        if "\r\n\r\n" in out:
            headers_text, body = out.split("\r\n\r\n", 1)
        else:
            headers_text, body = "", out.split("\n\n", 1)[-1]
        if r.returncode != 0 and status == 0:
            # gh prints errors to stderr; detect 404
            if "404" in r.stderr:
                status = 404
        try:
            data = json.loads(body) if body.strip().startswith(("{","[")) else None
        except Exception:
            data = None
        # Check for rate-limit before deciding on success/failure
        if _is_rate_limited(status, body, r.stderr, headers_text):
            if attempt < len(_BACKOFF_SCHEDULE):
                # Pick a LOCAL sleep for the next attempt; never mutate the global schedule.
                base = _BACKOFF_SCHEDULE[attempt]
                suggested = _parse_retry_after(headers_text)
                # Cap any header-derived suggestion at 600s so no single stall exceeds 10 min.
                next_sleep = min(suggested, 600) if suggested else base
                continue  # retry
            else:
                # Exhausted retries — return distinct 429 signal
                print(f"  [rate-limit] exhausted retries for {path} — skipping (will retry on next run)", flush=True)
                return False, None, 429
        # Not rate-limited — normal outcome
        return (status == 200 and data is not None), data, status
    # Should not reach here, but guard
    return False, None, 429

def already_done():
    done = set()
    if os.path.exists(META):
        for ln in open(META):
            try:
                d = json.loads(ln); done.add((d["owner"].lower(), d["repo"].lower()))
            except: pass
    return done

def main():
    cands = json.load(open(CAND))
    done = already_done()
    fmeta = open(META, "a")
    n_incl = 0
    for i, c in enumerate(cands, 1):
        key = (c["owner"].lower(), c["repo"].lower())
        if key in done:
            continue
        owner, repo = c["owner"], c["repo"]
        rec = {"owner": owner, "repo": repo, "url": c["url"], "categories": c["categories"]}
        ok, data, status = gh_api(f"repos/{owner}/{repo}")
        time.sleep(0.08)
        if not ok:
            if status == 429:
                # Rate-limit exhausted: do NOT write a meta line so this candidate
                # is re-attempted on the next run (resume invariant preserved).
                print(f"  WARNING: rate-limit-exhausted for {owner}/{repo} — NOT recording; re-run to retry.", flush=True)
                print("  Stopping run early so you can resume after the rate limit resets.", flush=True)
                fmeta.close()
                sys.exit(2)  # exit code 2 = rate-limited stop; resume is safe
            rec.update(included=False, reason="dead_or_renamed", http=status)
            fmeta.write(json.dumps(rec)+"\n"); fmeta.flush(); continue
        full = data.get("full_name", f"{owner}/{repo}")
        rec["full_name"] = full
        # languages
        lok, langs, lstatus = gh_api(f"repos/{full}/languages")
        time.sleep(0.08)
        if lstatus == 429:
            # Rate-limit exhausted on languages call: skip writing meta, stop.
            print(f"  WARNING: rate-limit-exhausted fetching languages for {full} — NOT recording; re-run to retry.", flush=True)
            print("  Stopping run early so you can resume after the rate limit resets.", flush=True)
            fmeta.close()
            sys.exit(2)
        langs = langs if (lok and isinstance(langs, dict)) else {}
        swift_bytes = int(langs.get("Swift", 0))
        total_bytes = sum(int(v) for v in langs.values()) or 1
        pushed = (data.get("pushed_at") or "")[:10]
        rec.update(
            default_branch=data.get("default_branch","main"),
            pushed_at=pushed, created_at=(data.get("created_at") or "")[:10],
            archived=bool(data.get("archived")), disabled=bool(data.get("disabled")),
            fork=bool(data.get("fork")), size_kb=data.get("size",0),
            stars=data.get("stargazers_count",0),
            license=(data.get("license") or {}).get("spdx_id"),
            languages=langs, swift_bytes=swift_bytes,
            swift_share=round(swift_bytes/total_bytes, 4),
            flags=[f for f,on in (("archived",data.get("archived")),
                                  ("fork",data.get("fork"))) if on],
        )
        # exclusion rules (ordered)
        if data.get("disabled"):
            rec.update(included=False, reason="disabled")
        elif pushed and pushed < CUTOFF:
            rec.update(included=False, reason="stale")
        elif swift_bytes < 3000 or rec["swift_share"] < 0.2:
            # incidental Swift (stray .swift file in a JS/C++/Obj-C project) or near-empty stub
            rec.update(included=False, reason="not_swift")
        else:
            rec.update(included=True, reason="ok"); n_incl += 1
        fmeta.write(json.dumps(rec)+"\n"); fmeta.flush()
        if i % 50 == 0:
            print(f"  {i}/{len(cands)} processed", flush=True)
    fmeta.close()
    # build included.json from full meta
    incl = []
    for ln in open(META):
        d = json.loads(ln)
        if d.get("included"):
            incl.append({k: d[k] for k in ("owner","repo","full_name","default_branch",
                         "stars","pushed_at","swift_bytes","swift_share","languages",
                         "categories","flags","license")})
    incl.sort(key=lambda x: -x["stars"])
    json.dump(incl, open(INCL,"w"), indent=2)
    # summary by reason
    from collections import Counter
    reasons = Counter(json.loads(ln)["reason"] for ln in open(META))
    print(f"\nDONE. included={len(incl)}  reasons={dict(reasons)}")

if __name__ == "__main__":
    main()
