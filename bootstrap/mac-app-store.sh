#!/usr/bin/env bash
# shellcheck disable=SC2086


APPS="$(command awk '{print $1}' <<< "
    1274495053      # Microsoft To Do
    668208984       # GIPHY CAPTURE
    1451685025      # WireGuard
    1365531024      # 1Blocker
    1529448980      # Reeder
")"
mas install $APPS
