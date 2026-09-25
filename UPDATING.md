# Syncing upstream

Use this guide when the user asks to update this fork from its source repository.

## Before editing

1. Read this guide and inspect `origin`, `upstream`, Git status, and recent history.
2. Fetch both remotes. Compare the fork with the latest `upstream/main`.
3. Inspect upstream commits and changed files. Group changes by tool and purpose.
4. Check current tools and settings in `home/`, `mise.toml`, `apps/`, and `tools/`.
5. Summarize important additions, removals, migrations, and conflicts.
6. Ask which unclear tools or workflows the user wants. Give a short explanation and recommendation.
7. Wait for answers before adding unclear tools or replacing current workflows.

## Current preferences

Use these as a starting point. Ask again when upstream changes the tools or their roles.

- Keep Chezmoi, Git, Herdr, Worktrunk, Television, and the existing `pix` tool.
- Exclude Jujutsu and Jujutsu-specific configs, channels, plugins, and workflows.
- Exclude tmux, sesh, Workmux, and hunk unless the user asks to add them.
- Do not assume that a tool is unused because its binary is absent. Inspect its config and use first.

## Sync

1. Preserve uncommitted work and personal settings.
2. Bring in every applicable upstream change, not only tool changes.
3. Adapt upstream changes to the Chezmoi layout under `home/`.
4. Keep excluded tools out of tool lists, lockfiles, templates, shell setup, and install scripts.
5. Keep the fork identity, personal paths, SSH settings, and machine-specific templates.
6. Regenerate the mise lockfile after tool changes. Preserve selected tools and their lock entries.
7. Update README or setup instructions when commands or layout change.
8. Review the full diff for dropped local settings, stale references, broken paths, and secrets.
9. Run `mise run check`, shell syntax checks, and `git diff --check`.
10. Show a concise change summary and test results.
11. Commit and push to `origin` only when the user asks.

Never push to `upstream`. Do not replace the Chezmoi migration with a blind merge or tree copy.
