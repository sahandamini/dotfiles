# Syncing upstream

Use this guide when the user asks to update this fork from
[aria-amini/dotfiles](https://github.com/aria-amini/dotfiles).

## Before editing

1. Read this guide. Inspect `origin`, `upstream`, Git status, and recent
   history.
2. If the upstream remote is missing, add it without tags. Upstream tags are old
   template releases.

   ```bash
   git remote add upstream https://github.com/aria-amini/dotfiles.git
   git config remote.upstream.tagOpt --no-tags
   ```

3. Fetch both remotes. List the commits in `main..upstream/main`.
4. Group upstream changes by tool and purpose. Compare them with `home/`,
   `mise.toml`, and `tools/`.
5. Sort each change: take it, skip it (a fork decision below), or ask.
6. Ask about each new or changed tool or workflow. Give a short explanation and
   a recommendation. Wait for the answers.

A tool is not unused because its binary is absent. Inspect its config and use
first.

## Fork decisions

These differ from upstream. Keep them unless the user changes them. Add each new
decision here; remove a decision when upstream adopts the same choice.

Keep:

- Git, Worktrunk, and lazygit as the version control tools.
- WSL support and the WezTerm config (Windows desktop). The MacBook runs Ghostty
  and the Lima VM.
- Catppuccin Frappe with no light/dark pair. Herdr uses the `terminal` theme
  with `auto_switch = false`.
- Television with its built-in channels plus the `git-log` graph override.
- hunk with `vcs = "git"`.
- `chrome-devtools-axi` for browser automation.
- `.zshrc` fully managed (`dot_zshrc.tmpl`). It sources the Vite+ env, so Vite+
  does not edit it.
- The Lima VM `devbox` with no host mounts and `minimumLimaVersion: 2.2.0`.
- Caddy for `*.lab.sahandamini.dev` with the Porkbun DNS plugin: the
  `setup-caddy` task, `~/.config/caddy-lab/env`, and the `caddy` installer
  phase.
- The fork's `[proxy]` and `[vm]` values in `home/.chezmoidata.toml`.
- The TanStack template in the `sahandamini/tanstack-template` fork. Its README
  has its own sync steps.
- The repo tools: the root `mise.toml`, `tools/` (`dev`, `imgview`,
  `mise-vite-plus`, `pix`), and the installer's `repo_tools` phase. Upstream
  has none of them.

Exclude:

- Jujutsu and everything built on it: jj configs, jj-waltz, jjui, jj-ryu, the
  herdr-jj plugin, `home/dot_config/tools/repos.toml`, and the T3 Code fork
  (`t3-fork-update`). Use the official `t3` npm package.
- tmux, sesh, and Workmux.
- playwriter, lavish-axi, and open-code-review.
- The Microsoft work setup and Azure tools.
- Upstream's personal infrastructure: Cloudflare DNS, the OpenBao vault schema,
  pi provider settings, model choices, and identity.
- `install-windows.ps1` and its Windows ignore rules. Windows uses WSL.

## Fork fixes

These fix upstream bugs. Do not let a sync undo them.

- macOS Nix: install with `--daemon`, then source
  `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`. The installer
  rejects `--no-daemon` on macOS.
- Login shell: use `/usr/bin/zsh`, never `command -v zsh`. A zsh under `$HOME`
  disappears with its tool, and sshd then rejects every login.
- Installer re-runs: run `mise use -g` only before the first chezmoi apply. Run
  chezmoi with `--no-tty` and stdin from `/dev/null`. Otherwise a conflict
  prompt waits behind the spinner.
- mise GitHub token: keep `credential_command = "gh auth token"` under
  `[settings.github]`. gh keeps its token in the keychain, where mise cannot
  read it.
- Caddy DNS challenge: keep `resolvers 1.1.1.1 8.8.8.8`. Lima's resolver and
  MagicDNS return no SOA records.
- mise lockfile: keep entries for `linux-arm64`, `linux-x64`, `macos-arm64`, and
  `macos-x64`. See README, "Updating tools".

## Sync

1. Preserve uncommitted work and personal settings.
2. Take every applicable upstream change, not only tool changes.
3. Adapt upstream changes to the chezmoi layout under `home/`.
4. Keep excluded tools out of tool lists, lockfiles, templates, shell setup,
   and installers.
5. After tool changes, regenerate the mise lockfile.
6. Update README and setup steps when commands or layout change.
7. Review the full diff for dropped settings, stale references, broken paths,
   and secrets.
8. Run `mise run check`, `shellcheck` on the installers, and `git diff --check`.
   Run `chezmoi apply --dry-run` on the Mac and on the VM.
9. Show a short change summary and the test results.
10. Commit and push to `origin` only when the user asks. Never push to
    `upstream`.
11. Record the sync point with `git merge -s ours upstream/main`. The next sync
    then lists only newer upstream commits.

Do not replace the chezmoi layout with a blind merge or tree copy.
