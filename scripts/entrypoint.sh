#!/bin/sh
set -e

if [ "$(id -u)" = "0" ]; then
  mkdir -p /paperclip/instances/default/logs
    chown -R node:node /paperclip
      exec gosu node "$@"
      else
        mkdir -p /paperclip/instances/default/logs
          exec "$@"
          fi
