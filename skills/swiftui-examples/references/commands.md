# Commands — flags, JSON schema, exit codes

Binary: `swiftui-ctx`. Catalog found via `--catalog`, `$SWIFTUI_CTX_CATALOG`, `./catalog`, or package-relative.
Global flags: `--json` · `--limit N` · `--platform ios|macos|cross|any` (default `ios`) · `--offline` · `--catalog <dir>`.
Input is normalized: a leading `@`/`.` and a trailing `(…)` signature are stripped (`@State`→`State`).

## Commands
| Command | Purpose |
|---|---|
| `lookup <api>` | Context pack: `consensus` (shapes %), `recommended` + `diverse` examples, `co_occurs_with`, deprecation, `doc:`. Start here. |
| `examples <api> [--shape S] [--repo R] [--page N]` | Ranked, paginated real call sites (curated ≤25/API sample). |
| `file <id\|permalink> [--smart\|--decl\|--chain\|--full]` | Fetch the real source live; `--smart` is the anchor-safe default. |
| `recipe <name>` / `recipes` | Multi-API production patterns: template + real examples. |
| `deprecated [<api>]` | Deprecated APIs in use + modern replacement (anti-patterns to avoid). |
| `repo <owner/name>` | A corpus repo's fingerprint, modernity, author authority. |
| `search <query>` | Intent/keyword → candidate APIs + recipes. |
| `stats` | Corpus overview + coverage. |
| `doctor` | Health check: confirms the catalog loads + prints version/repos/SDK. Run first if a query errors. |
| `conformances <protocol>` | Real conformers of `View`/`ViewModifier`/`ButtonStyle`/`Layout`/… (custom-component evidence). |
| `bridges [<filter>]` | UIKit↔SwiftUI bridges (`UIViewRepresentable`/`UIViewControllerRepresentable`…) across the corpus + permalinks. |
| `settings` | Production settings/preferences screens + the `Form` vocab they use. |
| `valueBuilders [<filter>]` | Real Font/Color/Animation/gradient value expressions (e.g. spring presets). |
| `rankings <dim>` | Top repos by `by_total_unique_apis · by_modifier_breadth · by_custom_components · most_modern_stack`. |
| `insights <section>` | Corpus signals: `modern-stack · deprecated · cooccurrence · external · components · categories`. |

## JSON envelope (`--json`)
```json
{ "ok": true, "schema_version": "v1",
  "result": { … },
  "next_actions": [ {"cmd": "swiftui-ctx file ex_…", "why": "see the full enclosing view"} ],
  "error": null }
```
Failure: `"error": {"class","code","message","retryable","suggestion"}` with `"ok": false`.

### `lookup` result fields
`api · kind · repo_count · total_uses · introduced_ios · deprecated · replacement? · doc ·
consensus:[{shape,pct}] · recommended:{id,repo,permalink,src,stars,author_authority,min_ios,score} ·
diverse:[…] · co_occurs_with:[sym] · recipes:[name] · low_corpus:bool`.

### `examples` result fields
`api · matched_in_sample · page · limit · platform · note · examples:[{id,repo,permalink,src,shape,stars,author_authority,min_ios,score}]`.
The `note` explains the curated-sample vs consensus-% relationship — read it before trusting counts.

### `file` result fields
`permalink · mode · range:{start,end} · code`. The range always contains the example's line.

## Exit codes → action
| Code | Meaning | Do |
|---|---|---|
| 0 | ok | proceed |
| 2 | usage (empty/bad args) | fix the invocation |
| 3 | not-found | read `error.suggestion` (did-you-mean), or `search "<broader>"` |
| 4 | network (live `file`) | retry once, then `file <id> --offline` (cached `src`) |
| 5 | no catalog | **STOP. Tell the user. Do NOT fabricate examples from memory.** |

## Notes
- `lookup <ProtocolName>` (e.g. `UIViewRepresentable`) is not a single API — it **redirects to its recipe** (exit 0).
- A `recommended` example is never a `score==0 && stars==0` repo, and container types (`Form`/`List`/…) only count when called with a trailing closure (kills same-named custom structs).
- `--offline` returns the stored one-line `src` (the full call head), not a fetched span — use only as a network fallback.
