#!/usr/bin/env bash
# shellcheck disable=SC2086


APPS="$(command awk '{print $1}' <<< "
    1365531024		# 1Blocker
    1569813296		# 1Password for Safari
    424390742		# Compressor
    424389933		# Final Cut Pro
    1481302432		# Instapaper Save
    409183694		# Keynote
    634148309		# Logic Pro
    634159523		# MainStage
    1274495053		# Microsoft To Do
    434290957		# Motion
    409203825		# Numbers
    1451552749		# Open In Webmail
    409201541		# Pages
    1529448980		# Reeder
    1376402589		# StopTheMadness
    1482490089		# Tampermonkey
    1451685025		# WireGuard
")"
mas install $APPS
