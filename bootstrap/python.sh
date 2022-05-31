#!/usr/bin/env bash
# shellcheck disable=SC2086


packages="$(command sed '/^#/d' <<< "
ffsubsync
ripe.atlas.tools
xkcdpass
yq
")"

pip3 install $packages
