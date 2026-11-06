---
description: Adopt iPhone Duo support in this Flutter app, step by step, with an interview first and approval between steps
argument-hint: "[step-name] [--plan-only] [--reset]"
---

Invoke the `iphone-duo:adopt` skill and follow it. Pass `$ARGUMENTS` through:

- no arguments: run discovery (or resume from `.iphone-duo/progress.md`) and continue with the next pending step.
- `<step-name>` (for example `responsive-layout`): run only that step, using the saved profile.
- `--plan-only`: run discovery and show the step plan, then stop without changing code.
- `--reset`: ask before deleting `.iphone-duo/`, then start over with discovery.
