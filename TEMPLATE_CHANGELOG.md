# Template Changelog

## 2026-04-02

- Fixed: Claude Code adapter fails with `--dangerously-skip-permissions cannot be used with root/sudo privileges` (#4)
  - Set `CLAUDE_CODE_BUBBLEWRAP=1` in Dockerfile — tells Claude Code it is running inside a container sandbox, bypassing the redundant root check while Docker's own isolation remains active
  - Replaced `gosu` with `setpriv --inh-caps=-all` in entrypoint to properly drop inherited Linux capabilities
  - Removed `gosu` package from Dockerfile (no longer needed; `setpriv` is part of the base image)
