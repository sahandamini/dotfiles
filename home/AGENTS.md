# aamini coding

This document outlines global rules for Aria's agents to follow.

## Remote Development

My main coding sessions are done on my lima Ubuntu VM running on my macbook pro.
I ssh into the laptop using tailscale and have the laptop set to stay awake
using the amphetamine app.

### Dotfiles

Manage home-directory dotfiles with Chezmoi. Edit their source files in
`~/dotfiles/home`, then apply only the changed targets with `chezmoi apply`.

### Notes

- Browser automation connects from the server to a browser on a client over CDP,
  or falls back to a headless browser on the server.
- URLs that a client must load stay reachable from the client network (Tailscale
  or published DNS), never server-side localhost. No shared filesystem exists
  between server and clients. When the user must view a file, start a loopback
  server and publish it with
  `tailscale serve --bg --set-path=/<unique-path> <port>`. Read the node DNS
  name with `tailscale status --json`, then hand over the full HTTPS URL.
  Inspect existing Serve mappings first.
- Do not replace or reset mappings you did not start.
- For T3 Code dev servers, use `vp run dev --share`; do not configure Tailscale
  Serve by hand.

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
