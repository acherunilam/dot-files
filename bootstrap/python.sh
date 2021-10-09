#!/usr/bin/env bash
# shellcheck disable=SC2086


packages="$(command sed '/^#/d' <<< "
ffsubsync
IMDbPY
xkcdpass
")"

pip3 install $packages
