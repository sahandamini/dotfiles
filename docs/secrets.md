# Secrets

The dotfiles hold one secret file: the Porkbun API keys that Caddy uses for the
`*.lab.sahandamini.dev` wildcard certificate. Chezmoi stores the file
age-encrypted at `home/dot_config/caddy-lab/encrypted_private_env.age`. The
target is `~/.config/caddy-lab/env` on the Lima VM.

One age key decrypts every encrypted file. Keep the key in Bitwarden. Never
paste the key or a secret into an agent chat.

## New machine

Run `bootstrap.sh`. When the repo holds encrypted files, setup asks for the age
key. Paste the `AGE-SECRET-KEY-...` line from Bitwarden. The input stays hidden.
Setup writes `~/.config/chezmoi/age-key.txt` (mode `600`) and the age settings
in `~/.config/chezmoi/chezmoi.toml`.

Press Enter to skip. Chezmoi then ignores the encrypted files, and the Caddy
step asks for the Porkbun keys instead.

With `--yes` or no terminal, setup cannot ask. Pass the key file instead:

```sh
DOTFILES_AGE_KEY_FILE=/path/to/age-key.txt bash bootstrap.sh --yes
```

Setup never overwrites an existing `chezmoi.toml`. If the file exists without
age settings, setup prints the settings to add. Merge them before all TOML
sections:

```toml
encryption = "age"

[age]
identity = "~/.config/chezmoi/age-key.txt"
recipient = "age1..." # The public key: chezmoi age-keygen -y <key file>
```

## Change a secret

On a machine with the age key:

```sh
chezmoi edit --apply ~/.config/caddy-lab/env
sudo systemctl restart caddy-lab
```

Commit and push the changed `.age` file. Other machines get it on the next
`dotfiles update`.

## Add a secret file

```sh
chezmoi add --encrypt <file>
```

Commit and push the new `.age` file. Add the target to the age rule at the end
of `home/.chezmoiignore` as `<target>{,.age}`, so machines without the key skip
it. Without age, chezmoi keeps the `.age` suffix in the target name.

## Security

The repo holds only ciphertext. The applied file and the age key are plaintext
on trusted machines. Processes under your account can read them. Avoid
`chezmoi diff`, `chezmoi cat`, and `chezmoi decrypt` in agent sessions.
