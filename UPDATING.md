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
   `setup/`, `tests/`, and the root `mise.toml`.
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
  and the Lima VM. WSL writes the Windows-side files until `bootstrap.ps1` sets
  up native Windows chezmoi. After that, native chezmoi owns the WezTerm config.
- Catppuccin Macchiato with no light/dark pair. Herdr uses the `terminal` theme
  with `auto_switch = false`.
- Television with its built-in channels plus the `git-log` graph override.
- hunk with `vcs = "git"`.
- `chrome-devtools-axi` for browser automation.
- `.zshrc` fully managed (`dot_zshrc.tmpl`). It sources the Vite+ env, so Vite+
  does not edit it.
- The Lima VM `devbox` with no host mounts and `minimumLimaVersion: 2.2.0`.
- Caddy for `*.lab.sahandamini.dev` with the Porkbun DNS plugin: the
  `setup-caddy` task, `~/.config/caddy-lab/env`, and the Lima-only `caddy`
  setup step. The step asks for missing Porkbun keys.
- Sign-in reminders in the setup summary for GitHub, Vercel, Railway, and
  Pulumi. The reminders only print text and never start a login.
- The fork's `[proxy]` and `[vm]` values in `home/.chezmoidata.toml`.
- The TanStack template in the `sahandamini/tanstack-template` fork. Its README
  has its own sync steps.

Exclude:

- Jujutsu and everything built on it: jj configs, jj-waltz, jjui, jj-ryu, the
  herdr-jj plugin and its `run_after_herdr_jj_plugin` hook,
  `home/dot_config/tools/repos.toml`, and the T3 Code fork
  (`t3-fork-update`). Use the official `t3` npm package.
- tmux, sesh, and Workmux.
- playwriter, lavish-axi, and open-code-review.
- The Microsoft work setup and Azure tools.
- Upstream's personal infrastructure: Cloudflare DNS, the OpenBao vault schema,
  the OpenBao Agent Caddy (`caddy-start`, `caddy-health`, `openbao/`, the
  Pitchfork `tls` daemon, `tests/test_tls.py`), pi provider settings, model
  choices, and identity.

## Fork fixes

These fix upstream bugs. Do not let a sync undo them.

- macOS Nix: install with `--daemon`, then source
  `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`. The installer
  rejects `--no-daemon` on macOS.
- Login shell: use `/usr/bin/zsh`, never `command -v zsh`. A zsh under `$HOME`
  disappears with its tool, and sshd then rejects every login.
- WSL interop: do not take upstream's `appendWindowsPath=false` step in
  `phase_apt`. `run_after_configure-wsl.sh` needs `cmd.exe` on PATH, and the
  managed `wsl.conf` sets `appendWindowsPath = true`.
- T3 Code: install `t3@latest` with `service install`, which also repairs an
  existing service. An old pin left a launcher that newer releases reject.
- Claude skills: keep `run_after_link-claude-skills.sh`, which links each skill
  into `~/.claude/skills` by name. Do not take upstream's single
  `~/.claude/skills` → `~/.agents/skills` link. Claude Code reads only one
  folder level, and the skills sit in group folders.
- T3 Code settings: point opencode at the mise shim, and repair an existing
  settings file. mise prunes the old version folder after an upgrade, so a
  versioned path breaks.
- mise GitHub token: keep `credential_command = "gh auth token"` under
  `[settings.github]`. gh keeps its token in the keychain, where mise cannot
  read it.
- Caddy DNS challenge: keep `resolvers 1.1.1.1 8.8.8.8`. Lima's resolver and
  MagicDNS return no SOA records.
- mise lockfile: keep entries for `linux-arm64`, `linux-x64`, `macos-arm64`, and
  `macos-x64` in `create_mise.lock`. See README, "Updating tools".

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
8. Run `mise run check`, `mise run test`, and `git diff --check`. Run
   `mise run test:e2e` when Docker is available. Run `chezmoi apply --dry-run`
   on the Mac and on the VM.
9. Show a short change summary and the test results.
10. Commit and push to `origin` only when the user asks. Never push to
    `upstream`.
11. Record the sync point with `git merge -s ours upstream/main`. The next sync
    then lists only newer upstream commits.

Do not replace the chezmoi layout with a blind merge or tree copy.
