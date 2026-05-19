# Raycast Scripts

Personal [Raycast](https://raycast.com) script collection.

## Structure

```
scripts/   # Raycast script commands
envs/      # Per-script .env files (gitignored)
utils.zsh   # Shared helper: load_env
```

## Scripts

| Script                | Icon | Description                                            |
| --------------------- | ---- | ------------------------------------------------------ |
| `base64.zsh`          | 🔡   | Encode/decode base64 — text, file path, or clipboard   |
| `get_graph_user.zsh`  | 👤   | Fetch MS Graph user info by ID or UPN                  |
| `imgflip-meme.zsh`    | 🖼️   | Generate a meme via imgflip webhook, copy to clipboard |
| `ipv4-get.zsh`        | 🌐   | Copy public IPv4 to clipboard                          |
| `no-as-a-service.zsh` | ❌   | Random rejection reason from No-as-a-Service           |
| `x.zsh`               | 🤖   | Copy Bruno ✕ character to clipboard                    |

## Environment files

Scripts that need secrets use `load_env` from `utils.zsh`. Each script auto-loads `envs/<script-name>.env` at runtime.

**Example** — `envs/get_graph_user.env`:

```env
AZURE_TENANT_ID="..."
AZURE_CLIENT_ID="..."
AZURE_CLIENT_SECRET="..."
```

**Example** — `envs/imgflip-meme.env`:

```env
N8N_WEBHOOK_BASE_URL="..."
N8N_WEBHOOK_IMGFLIP_API_KEY="..."
```

> **Keep `envs/` out of version control.**

## Adding a new script

1. Create `scripts/my-script.zsh` with Raycast metadata headers.
2. Source the helper and call `load_env`:
   ```bash
   source "$HOME/Raycast/utils.zsh"
   load_env VAR1 VAR2 || exit 1
   ```
3. Create the matching `envs/my-script.env` with the required variables.
