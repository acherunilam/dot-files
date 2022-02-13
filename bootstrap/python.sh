#!/usr/bin/env bash
# shellcheck disable=SC2086


packages="$(command sed '/^#/d' <<< "
ffsubsync
IMDbPY
ripe.atlas.tools
xkcdpass
yubikey-manager
")"

pip3 install $packages
