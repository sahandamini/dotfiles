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
5. Sort each change. Take upstream's choice by default, including deletions of
   skills, tools, and config. Skip a change only when an Exclude entry below
   covers it. Ask when a change conflicts with a Keep entry or a fork fix.
6. For each change that you ask about, give a short explanation and a
   recommendation. Wait for the answers.

A tool is not unused because its binary is absent. Inspect its config and use
first.

## Fork decisions

Upstream is the source of truth. Take its choices unless an entry below names a
difference. Add each new decision here; remove a decision when upstream adopts
the same choice.

Keep:

- Git, Worktrunk, and lazygit as the version control tools. Port upstream's
  jj-based workflows to Git, as `app:new` and the AGENTS.md shipping rules do.
- The WezTerm config, templated from the theme data. WSL itself runs with
  defaults, like upstream: no managed `.wslconfig`, `wsl.conf`, or `/etc/hosts`.
  `bootstrap.ps1` (native Windows chezmoi) owns the WezTerm config.
- Catppuccin Macchiato with no light/dark pair. Herdr uses the `terminal` theme
  with `auto_switch = false`.
- Emacs key bindings in zsh (`bindkey -e`), not vi mode.
- hunk with `vcs = "git"`.
- `chrome-devtools-axi` for browser automation.
- nvim plugin versions in `nvim/lazy-lock.json` at the repo root, linked into
  `~/.config/nvim`. `dotfiles update` updates the plugins, checks that nvim
  starts, and commits only the lockfile. Upstream commits a plain managed
  lockfile, which prompts a chezmoi conflict after each Lazy update.
- The Lima instance name `devbox`, with no host mounts and
  `minimumLimaVersion: 2.2.0`.
- Caddy for `*.lab.sahandamini.dev` with the Porkbun DNS plugin: the
  `setup-caddy` task, the Lima-only `caddy` setup step, and the age-encrypted
  `~/.config/caddy-lab/env`. The step asks for the Porkbun keys when age is not
  set up.
- Sign-in reminders in the setup summary for GitHub, Vercel, Railway, and
  Pulumi. The reminders only print text and never start a login.
- The fork's `[proxy]` and `[vm]` values in `home/.chezmoidata.toml`.
- App templates from the `sahandamini/tanstack-template` fork (`tanstack` and
  `astro`). The fork removes jj and upstream's domain. Its README has its own
  sync steps.
- The Style section in `home/AGENTS.md`. Upstream removed its code and writing
  rules.
- The `gpt-5.6-luna` explore model in the opencode config.

Exclude:

- Jujutsu and everything built on it: jj configs, jj-waltz, jjui, jj-ryu, ryu
  commands in AGENTS.md, the herdr-jj plugin and its
  `run_onchange_after_herdr_jj_plugin` hook, and jj fork data in
  `.chezmoidata.toml`.
- The T3 Code fork runtime: `T3_FORK_*`, `switch_t3_to_fork`, `t3-update`, the
  Python `t3` launcher, and the `T3_VERSION` pin. Install the official
  `t3@latest`.
- tmux, sesh, and Workmux.
- playwriter, lavish-axi, and open-code-review.
- The Microsoft work setup and Azure tools.
- Upstream's personal infrastructure: Cloudflare DNS and its tools (`cf`,
  `wrangler`, `caddy-cf`), the Cloudflare Caddy (`caddy-start`, `caddy-health`,
  the Pitchfork `tls` daemon, `tests/test_tls.py`), upstream's encrypted
  credentials and age key, `impeccable-decision`, pi provider settings, model
  choices, and identity.

## Fork fixes

These fix upstream bugs. Do not let a sync undo them.

- macOS Nix: install with `--daemon`, then source
  `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`. The installer
  rejects `--no-daemon` on macOS.
- Login shell: use `/usr/bin/zsh`, never `command -v zsh`. A zsh under `$HOME`
  disappears with its tool, and sshd then rejects every login.
- T3 Code: install `t3@latest` with `service install` when the service is
  missing or broken. After that, `t3 update` moves to new releases. An old pin
  once left a launcher that newer releases reject.
- Claude skills: keep `run_after_link-claude-skills.sh`, which links each skill
  into `~/.claude/skills` by name. Do not take upstream's single
  `~/.claude/skills` → `~/.agents/skills` link. Claude Code keeps its
  account-synced skills in `~/.claude/skills/synced`; a folder link would move
  them into `~/.agents/skills`, where other agents load them.
- T3 Code settings: point opencode at the mise shim, and repair an existing
  settings file. mise prunes the old version folder after an upgrade, so a
  versioned path breaks.
- mise GitHub token: keep `credential_command = "gh auth token"` under
  `[settings.github]`. gh keeps its token in the keychain, where mise cannot
  read it.
- Caddy DNS challenge: keep `resolvers 1.1.1.1 8.8.8.8`. Lima's resolver and
  MagicDNS return no SOA records.

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
8. Run `mise run check`, `mise run test`, and `git diff --check` on the Lima
   VM. The setup tests need Linux. Run `mise run test:e2e` when Docker is
   available. Run `chezmoi apply --dry-run` on the Mac and on the VM.
9. Show a short change summary and the test results.
10. Commit and push to `origin` only when the user asks. Never push to
    `upstream`.
11. Record the sync point with `git merge -s ours upstream/main`. The next sync
    then lists only newer upstream commits.

Do not replace the chezmoi layout with a blind merge or tree copy.
