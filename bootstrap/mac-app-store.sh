#!/usr/bin/env bash
# shellcheck disable=SC2086


apps="$(command awk '{print $1}' <<< "
1274495053      # Microsoft To Do
668208984       # GIPHY CAPTURE
1451685025      # WireGuard
1365531024      # 1Blocker
1480068668      # Messenger
1529448980      # Reeder 5
497799835       # Xcode
")"

mas install $apps