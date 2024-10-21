#!/usr/bin/env bash
# shellcheck disable=SC2086

APPS="$(command awk '{print $1}' <<<"
    1365531024      # 1Blocker
    1569813296      # 1Password for Safari
    937984704       # Amphetamine
    996933579       # AirTurn Manager
    424390742       # Compressor
    424389933       # Final Cut Pro
    363738376       # forScore
    1444383602      # Goodnotes
    1481302432      # Instapaper Save
    409035833       # iReal Pro
    409183694       # Keynote
    634148309       # Logic Pro
    634159523       # MainStage
    1274495053      # Microsoft To Do
    434290957       # Motion
    409203825       # Numbers
    1451552749      # Open In Webmail
    409201541       # Pages
    639968404       # Parcel
    1529448980      # Reeder
    6471380298      # StopTheMadness Pro
    1482490089      # Tampermonkey
    497799835       # Xcode
")"
mas install $APPS
