# aamini coding

This document outlines global rules for Sahand's agents to follow.

## Remote Development

My main coding sessions are done on my lima Ubuntu VM running on my macbook pro.
I ssh into the laptop using tailscale and have the laptop set to stay awake
using the amphetamine app.

### Dotfiles

Manage home-directory dotfiles with Chezmoi. The source repo lives at
`~/.local/share/chezmoi`, and `~/dotfiles` links to it. Edit source files under
`~/dotfiles/home`, then apply only the changed targets with `chezmoi apply`.

### Notes

- Browser automation prefers Chrome on the client over CDP. Detect the online
  client with `tailscale status`. Ask the user to start Chrome with remote
  debugging when no client browser runs. Use the server headless browser only
  when no client is reachable. Use the full Playwright Chromium with
  `--headless=new`; never use `chrome-headless-shell`. Set
  `CHROME_DEVTOOLS_AXI_BROWSER_URL` on every axi call.
- URLs that a client must load stay reachable from the client network (Tailscale
  or published DNS), never server-side localhost. No shared filesystem exists
  between server and clients. When the user must view a file, start a loopback
  server and publish it with
  `tailscale serve --bg --https=8443 --set-path=/<unique-path> <port>`. Read the
  node DNS name with `tailscale status --json`, then hand over the full HTTPS
  URL. Inspect existing Serve mappings first.
- Do not replace or reset mappings you did not start.
- Caddy terminates TLS on the Tailscale IP at port 443 and proxies to the
  Pitchfork proxy on loopback port 9443. App URLs are
  `https://<name>.lab.sahandamini.dev`, with a public Let's Encrypt certificate.
  Hostnames are single-level: slugs flatten directory dots to hyphens
  (`app.worktree` serves as `app-worktree`). Nested hostnames
  (`worktree.app.lab…`) and direct `:9443` access do not work: the wildcard
  certificate covers one level, and the proxy binds loopback only. Register a
  worktree with
  `pitchfork proxy add <slug> --daemon dev --dir <worktree-root>`.
- Port ownership on the Tailscale IP: Caddy owns port 443. Ad-hoc Tailscale
  Serve publishes set an explicit `--https` port in the 8443–8499 range, never
  the default 443.
- For T3 Code dev servers, use `vp run dev --share`; do not configure Tailscale
  Serve by hand.
- Herdr panes run non-login shells on Linux. Keep `shell_mode = "login"` in
  `~/.config/herdr/config.toml`, so `.zprofile` PATH setup runs.

## Rules

### Version Control

- Use Git for version control.
- Preserve uncommitted work before switching branches or worktrees.
- Review the status and diff before committing.

### Style

- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long-term
  maintanability.
- Never write comments that restate what the code already says — if a comment
  explains _what_ the code does, delete it and rename or restructure the code
  instead. Comments must add information the code cannot express. Allowed
  - **Critical context** — why a non-obvious decision was made, constraints
    imposed by external systems, or links to reference material.
  - **Section markers** — short labels (often one word) like `// Shared`, or the
    banner style `// ===== Section =====`, to annotate blocks of code.
- Please make plans incredibly terse. I find long plans with too many details
  very difficult to read.
- For Technical text, use ASD-STE100 style. Max 20 words per sentence in
  instructions, 25 in descriptions. Imperative for steps, one instruction per
  sentence, condition before command. Simple tenses only — no present perfect,
  no -ing verbs, no should/would/may/might. Active voice. One word per meaning —
  no synonym rotation. No contractions, keep articles and "that". Delete filler:
  simply, robust, seamlessly, leverage. Code and identifiers stay exact.
