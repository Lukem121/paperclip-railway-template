# Template Changelog

## 2026-04-17

- Fixed: WebSocket proxy upstream errors no longer crash the Node process (#6, duplicate #7) — `http-proxy` can pass a socket on WS failures, which has no `writeHead`; the wrapper now sends JSON 503 only for HTTP responses and destroys the socket otherwise.
- Changed: Paperclip pin `v2026.325.0` → `v2026.416.0` (latest stable at bump time; routine upstream uptake). **Upgrade note:** upstream v2026.416.0 adds migrations including `pg_trgm`; embedded Postgres in this template should allow `CREATE EXTENSION`, but external DB users may need DBA to run `CREATE EXTENSION IF NOT EXISTS pg_trgm;` before upgrade — see [paperclip v2026.416.0 release notes](https://github.com/paperclipai/paperclip/releases/tag/v2026.416.0).
- Changed: Runtime image aligned with [upstream Paperclip production Dockerfile](https://github.com/paperclipai/paperclip/blob/master/Dockerfile) — `HOME=/paperclip`, `PAPERCLIP_INSTANCE_ID`, `PAPERCLIP_CONFIG`, `OPENCODE_ALLOW_ALL_MODELS=true`, and apt packages `git`, `openssh-client`, `jq`, `ripgrep` (agent/git tooling parity).

## 2026-04-02

- Fixed: Claude Code adapter fails with `--dangerously-skip-permissions cannot be used with root/sudo privileges` (#4)
  - Set `CLAUDE_CODE_BUBBLEWRAP=1` in Dockerfile — tells Claude Code it is running inside a container sandbox, bypassing the redundant root check while Docker's own isolation remains active
  - Replaced `gosu` with `setpriv --inh-caps=-all` in entrypoint to properly drop inherited Linux capabilities
  - Removed `gosu` package from Dockerfile (no longer needed; `setpriv` is part of the base image)
