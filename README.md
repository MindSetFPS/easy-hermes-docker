# Easy Hermes Docker

Self-contained [Hermes Agent](https://github.com/nousresearch/hermes) with preconfigured ssh terminal for safe Linux environment.

## Why

When i tried hermes with docker, i found many permision issues related to users and ownership. I had to constantly delete files as root, restart services, etc, and the agent could not interact with the local terminal. This is my attempt to simplify and automate the process by isolating everything into containers.

## Quick start

```bash
docker compose up -d --build
```

| Service | Port | What |
|---|---|---|
| Gateway API | `:8642` | Hermes agent endpoint |
| Dashboard | `:9119` | Web UI (config, logs, sessions) |

On first run, the terminal container auto-generates an SSH key pair into `hermes/ssh/` and
the agent connects automatically.

## Usage

```bash
# Enter the agent container (with venv activated)
docker exec -it -u hermes hermes bash --init-file .venv/bin/activate
```

### Network isolation

The terminal container is on a dedicated `internal` network (`internal: true`) —
no internet access and unreachable from other containers. Only `hermes` can connect
to it over SSH. This prevents any lateral movement if another container on the host
is compromised.

```
hermes  ──┬── default  (internet / API calls)
          └── internal ─── terminal (isolated)
```

## Project structure

```
hermes-agent/
├── docker-compose.yml         # Service definitions
├── terminal.Dockerfile        # SSH sandbox image
├── terminal-entrypoint.sh     # Auto-generates SSH keys on first run
├── hermes-entrypoint.sh       # Pre-entry hook for whatsapp bridge
├── config.yaml                # Agent configuration (git-tracked)
├── hermes/                    # Runtime state (gitignored except config)
│   ├── config.yaml            # Active config (same as above, mounted directly)
│   ├── .env                   # API keys (gitignored)
│   ├── auth.json              # Credentials cache (gitignored)
│   ├── state.db               # Persistent state (gitignored)
│   ├── ssh/
│   │   ├── terminal-key       # SSH private key (auto-generated, gitignored)
│   │   └── terminal-key.pub   # SSH public key (auto-generated, gitignored)
│   └── .ssh/
│       └── config             # Disables host key checking for terminal
├── .gitignore
└── README.md
```

## How it works

### Terminal SSH

A sidecar container (`hermes-terminal`) runs an SSH server. On startup, its entrypoint
generates an ED25519 key pair into `hermes/ssh/` if one doesn't exist, copies the public
key into the `agent` user's `authorized_keys`, and starts `sshd`.

The `hermes` container connects via `TERMINAL_SSH_KEY=/opt/data/ssh/terminal-key`.

To change the terminal container's timezone, set `TZ` (e.g. `TZ=America/Bogota`) in
your `.env` file. It is applied system-wide at startup, so SSH sessions and
`date` inside the container agree.

### Config

`config.yaml` at the project root is the source of truth. The compose file mounts
`./hermes:/opt/data`, so `config.yaml` lives directly inside the data directory —
no need for separate file mounts.

### WhatsApp bridge

The image ships a WhatsApp bridge that runs `npm install` at startup into
`/opt/hermes/scripts/whatsapp-bridge/`. That directory is owned by the image's
default uid (10000), so npm fails with EACCES after the user is remapped.
`hermes-entrypoint.sh` runs before the main entrypoint and chowns the directory
to the target UID/GID from `HERMES_UID` / `HERMES_GID`.

## Environment variables

Set these in a `.env` file alongside `docker-compose.yml`:

| Variable | Default | Description |
|---|---|---|
| `HERMES_UID` | `1000` | Host UID — entrypoint remaps the internal `hermes` user to this |
| `HERMES_GID` | `1000` | Host GID |
| `TZ` | `America/Bogota` | Timezone for the terminal (SSH) container, e.g. `America/Bogota` |
| `ANTHROPIC_API_KEY` | — | Anthropic API key |
| `OPENAI_API_KEY` | — | OpenAI API key |
| `TELEGRAM_BOT_TOKEN` | — | Telegram bot token (optional) |

## Terminal env vars (set automatically)

| Variable | Value |
|---|---|
| `TERMINAL_SSH_HOST` | `terminal` |
| `TERMINAL_SSH_USER` | `agent` |
| `TERMINAL_SSH_PORT` | `22` |
| `TERMINAL_SSH_KEY` | `/opt/data/ssh/terminal-key` |

## Security

This setup prioritizes convenience for local / trusted-network use. Review these
before deploying on a shared network or internet-facing host.

### 🔴 High

| # | Flaw | File | Detail |
|---|---|---|---|
| 1 | **Hardcoded SSH password** | `terminal.Dockerfile:5` | `agent:agent` — known to anyone with the repo |
| 2 | **Password auth enabled** | `terminal.Dockerfile:10` | Anyone on the Docker network can SSH in with `agent:agent` |
| 3 | **Passwordless sudo** | `terminal.Dockerfile:12` | `agent ALL=(ALL) NOPASSWD:ALL` — full root if SSH is compromised |
| 4 | **Dashboard on 0.0.0.0** | `docker-compose.yml:9` | Port `9119` reachable from the LAN. Fix: `127.0.0.1:9119:9119` |
| 5 | **Gateway API on 0.0.0.0** | `docker-compose.yml:8` | Port `8642` reachable from the LAN — anyone can send commands to the agent |

### 🟡 Medium

| # | Flaw | Detail |
|---|---|---|
| 6 | **SSH private key on shared bind mount** | `./hermes/ssh/` is writable by the terminal container and readable by any container that mounts it. The key has no passphrase. |
| 7 | **No error handling in entrypoint** | `terminal-entrypoint.sh` uses `set -e` with no trap — if `ssh-keygen` fails, sshd never starts and the container restarts silently. |

## Redeploy

```bash
git clone <repo>
cd hermes-agent
docker compose up -d --build
```

The `hermes/` directory (SSH keys, DB, sessions, cache) auto-creates on first start.
Your `config.yaml` is the only file you need to maintain and version.

## Git-tracked files

Only these files are tracked. All are free of secrets — `api_key` fields in `config.yaml`
are empty by default.

```
.gitignore
README.md
docker-compose.yml
hermes-entrypoint.sh
hermes/config.yaml
hermes/.ssh/config
terminal-entrypoint.sh
terminal.Dockerfile
```

Runtime state (`auth.json`, `.env`, `state.db`, `ssh/terminal-key`, `known_hosts`,
backups, caches, logs, sessions, etc.) is gitignored and never committed.

---

## About

Built by [Daniel](https://x.com/0xDESKOBAR). If this saved you a headache and you know of an internship or entry level role on LLMs or infrastructure, I'd be grateful to hear.