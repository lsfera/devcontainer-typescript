# devcontainer-typescript

A reusable [Dev Container](https://containers.dev) for Node.js / TypeScript projects.
Projects live as separate git repos under `ws/` (not tracked here); one of them at a
time is mounted into the container at `/workspace`.

## What's in the container

- Image `mcr.microsoft.com/devcontainers/typescript-node:26-trixie`, plus Bun, pnpm,
  ripgrep, [rtk](https://github.com/rtk-ai/rtk) and the Claude Code CLI.
- Docker outside of Docker: the host's Docker socket, so the container can run
  sibling containers and Testcontainers (`TESTCONTAINERS_*` are preset).
- The `devcontainer` bridge network, shared with sibling containers.
- SSH agent forwarding from the host (Docker Desktop's `/run/host-services/ssh-auth.sock`), and the host's `known_hosts`.
- Forwarded ports: `3001`, `5173` (Vite dev), `4173` (Vite preview).
- VS Code extensions: Claude Code, Biome, Todo Tree.

## Setup

1. Install Docker and the Dev Containers CLI or the VS Code Dev Containers extension.
2. Load your SSH key into the host agent so git over SSH works inside the container.
   `initialize.sh` does this automatically when the agent is empty, but it can't prompt
   for a passphrase, so run it by hand the first time (or for a non-default key):

   ```bash
   .devcontainer/scripts/setup-ssh-agent.sh            # defaults to ~/.ssh/id_ed25519
   .devcontainer/scripts/setup-ssh-agent.sh ~/.ssh/other_key
   ```

3. Clone the projects you work on into `ws/`:

   ```bash
   git clone git@github.com:<you>/<project>.git ws/<project>
   ```

## Usage

Start the container with `up.sh`, from any directory:

```bash
./up.sh            # reopen the last project
./up.sh breeder    # mount ws/breeder at /workspace
```

Switching projects recreates the container, since the mount is fixed when the container
is created. The choice is saved in `.devcontainer/.env`, so later runs, or VS Code's
**Reopen in Container**, reuse the last project. Without any choice it defaults to
`circuit-breaker`.

Each project gets its own `node_modules` volume (`devcontainer-typescript-<project>-node_modules`),
so switching doesn't mix installs. On create, `pnpm install` runs if the project has a
`package.json`.

## Claude Code state

Claude state is kept inside the mounted project so it survives rebuilds:

| In the container    | Stored in                          |
| ------------------- | ---------------------------------- |
| `~/.claude-mem`     | `/workspace/.claude-mem`           |
| `~/.claude/plugins` | `/workspace/.claude-plugins-cache` |
| project settings    | `/workspace/.claude`               |

These paths are added to the project's `.git/info/exclude`, so they are never
committed. The [claude-mem](https://github.com/thedotmack/claude-mem) plugin is
installed on start if it is missing.

## Layout

```
.devcontainer/
  devcontainer.json         container definition
  docker-compose.yml        service, /workspace mount, network
  scripts/
    initialize.sh           host: picks WS_PROJECT, writes .env, loads SSH key
    post-create.sh          once per container: packages, pnpm, Claude CLI
    post-start.sh           every start: Claude state links, claude-mem, rtk
    setup-ssh-agent.sh      host: load an SSH key into the agent
ws/                         your project repos (git-ignored)
up.sh                       start the container, optionally switching project
```

## License

[MIT](LICENSE)
