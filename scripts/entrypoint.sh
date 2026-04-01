#!/bin/sh
set -e
# When Railway mounts a volume at /paperclip it is often not writable by the node user.
# Create dirs Paperclip needs and ensure the whole tree is owned by node.
mkdir -p /paperclip/instances/default/logs
chown -R node:node /paperclip

# ---------- Fix for GitHub issue #4 ----------
# Claude Code refuses --dangerously-skip-permissions when it detects
# root / sudo / elevated capabilities.  `gosu` drops uid/gid but keeps
# inherited Linux capabilities, which Claude Code interprets as elevated
# privilege.
#
# `setpriv` (util-linux, pre-installed on Debian Bookworm) lets us
# explicitly clear all inherited + ambient capabilities so the child
# process looks like a genuinely unprivileged user.
#
# We also unset any SUDO_* env vars that might leak from the container
# runtime, as Claude Code checks for those too.
unset SUDO_USER SUDO_UID SUDO_GID SUDO_COMMAND 2>/dev/null || true
 
exec setpriv \
  --reuid=node \
  --regid=node \
  --init-groups \
  --inh-caps=-all \
  "$@"
