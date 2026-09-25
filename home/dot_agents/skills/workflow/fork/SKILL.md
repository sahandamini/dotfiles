---
name: fork
description: Guidelines for forking a github repo in order to extend custom
functionality.
---

# Fork workflow

For this dotfiles fork, read `UPDATING.md` before each upstream sync. Follow its
tool review and user clarification steps.

Forks use two remotes: `origin` (the fork) and `upstream` (the source repo).
Never push to `upstream`. Local `main` is the fork's source of truth. Sync from
upstream by merge. Never rebase `main` onto upstream.

1. Run `git fetch upstream`.
2. Create a temporary branch from `main`.
3. Merge `upstream/main` into the temporary branch.
4. Resolve conflicts. Build. Run focused tests.
5. Stop. Show the result to the user. Wait for approval.
6. On approval, fast-forward or merge the result into `main` and push `main`.
7. Delete the temporary branch.

Retire old fork branches only after their changes are merged. Moving `main`
backwards or sideways needs user approval first.
