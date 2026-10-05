# Syncing upstream

Use this guide when the user asks to update this fork from its source repository.

## Before editing

1. Read this guide and inspect `origin`, `upstream`, Git status, and recent history.
   Add the upstream remote if it is missing:
   `git remote add upstream https://github.com/aria-amini/dotfiles.git`.
   Then run `git config remote.upstream.tagOpt --no-tags`. Upstream tags are
   old template releases and do not apply to this repo.
2. Fetch both remotes. Compare the fork with the latest `upstream/main`.
3. Inspect upstream commits and changed files. Group changes by tool and purpose.
4. Check current tools and settings in `home/`, `mise.toml`, and `tools/`.
5. Summarize important additions, removals, migrations, and conflicts.
6. Ask which unclear tools or workflows the user wants. Give a short explanation and recommendation.
7. Wait for answers before adding unclear tools or replacing current workflows.

## Current preferences

Use these as a starting point. Ask again when upstream changes the tools or their roles.

- Keep Chezmoi, Git, Herdr, Worktrunk, lazygit, Television, and the existing `pix` tool.
- Television uses its built-in channels plus a `git-log` graph override. Do not re-add the community channel set.
- Exclude Jujutsu and Jujutsu-specific configs, channels, plugins, and workflows (jj-waltz, jjui, jj-ryu).
- Exclude tmux, sesh, and Workmux unless the user asks to add them.
- Keep hunk with `vcs = "git"` in its config.
- Use `chrome-devtools-axi` for browser automation. Do not add playwriter.
- Keep the TanStack app template in the `sahandamini/tanstack-template` fork, not in this repo. Its README has the sync steps.
- Exclude Microsoft work setup and Azure tools (work registries, Azure DevOps credentials, azure-cli).
- Keep WSL support and the WezTerm config. The user has a Windows desktop with WSL and WezTerm. The MacBook runs Ghostty and the Lima VM.
- Keep the theme stack and machine data in `home/.chezmoidata.toml`.
- Use Catppuccin Frappe with no light/dark pair. Herdr uses the `terminal` theme with `auto_switch = false`.
- Exclude the upstream T3 Code fork (`t3-fork-update`, fork runtime releases). Use the official `t3` npm package.
- Keep the Lima VM without host mounts.
- Skip upstream's personal infrastructure: the OpenBao vault schema, pi provider settings, model choices, and identity. Keep the fork's `[proxy]` and `[vm]` values in `home/.chezmoidata.toml`.
- Keep Caddy for `*.lab.sahandamini.dev` with the Porkbun DNS plugin (`setup-caddy` task, `~/.config/caddy-lab/env`). Upstream uses Cloudflare and OpenBao; do not adopt those.
- Keep the repo at `~/.local/share/chezmoi` with the managed `~/dotfiles` link.
- Keep `.bash_profile` write-once (`modify_dot_bash_profile`), like upstream.
- Skip upstream's Windows installer (`install-windows.ps1`) and its Windows-only ignore rules. Windows uses WSL.
- Keep `.zshrc` fully managed (`dot_zshrc.tmpl`). Do not adopt upstream's write-once `modify_dot_zshrc`.
- Do not assume that a tool is unused because its binary is absent. Inspect its config and use first.

## Known upstream pitfalls

- The Nix installer rejects `--no-daemon` on macOS. Use `--daemon` and source `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`.
- Set the login shell to the system zsh (`/usr/bin/zsh`), never `command -v zsh`. A mise or Nix zsh under `$HOME` disappears when its tool is removed, and sshd then rejects every login with `Permission denied (publickey)`.
- Deploy `home/dot_config/mise/mise.lock` with platform entries for `linux-arm64`, `linux-x64`, `macos-arm64`, and `macos-x64`. Regenerate it with `GITHUB_TOKEN=$(gh auth token) mise lock --global --platform ...` after tool changes.

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
12. After the port, record the sync point with `git merge -s ours upstream/main`, so the next sync lists only newer upstream commits.

Never push to `upstream`. Do not replace the Chezmoi migration with a blind merge or tree copy.
