# References — audit-swiftui-design-review

This skill carries **no design rules of its own**. All design truth lives in the shared knowledge base,
so the reviewer and the generator (`build-ios-swiftui`) cannot drift:

- `${CLAUDE_PLUGIN_ROOT}/references/_shared/hig-design-rubric.md` — measurable HIG rules + Apple URLs.
- `${CLAUDE_PLUGIN_ROOT}/references/_shared/liquid-glass-design.md` — iOS 26 Liquid Glass design language.
- `${CLAUDE_PLUGIN_ROOT}/references/_shared/ux-smell-catalog.md` — qualitative UX smells (detect cues).
- `${CLAUDE_PLUGIN_ROOT}/references/_shared/design-finding-schema.md` — finding format + Design Score.
- `${CLAUDE_PLUGIN_ROOT}/references/_shared/design-claims-blacklist.md` — myths to never assert.

Mechanism (not rules): `scripts/swiftui-capture.sh` (capture), `scripts/swiftui-lint.sh` (`dr-*` tells),
`scripts/a11y-audit/` (optional `performAccessibilityAudit`).
