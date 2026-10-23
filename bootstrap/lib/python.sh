#!/usr/bin/env bash

set -euo pipefail

TOOLS=(
	bashplotlib
	black
	blaeu
	cinemagoer
	ffsubsync
	hashid
	ripe.atlas.tools
	torf-cli
	xkcdpass
)
if [[ "$OSTYPE" == "darwin"* ]]; then
	pip3 config set global.break-system-packages true
	pip3 config set global.user true
fi
pipx upgrade --install "${TOOLS[@]}"
