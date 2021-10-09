#!/usr/bin/env bash
# shellcheck disable=SC2086


packages="$(command sed '/^#/d' <<< "
fast-cli
ffmpeg-progressbar-cli
tplink-lightbulb
")"

npm install --global $packages
