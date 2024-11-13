#!/usr/bin/env bash

PKGS=(
	bashplotlib
	black
	blaeu
	cinemagoer
	ffsubsync
	hashid
	mnamer
	Pillow
	ripe.atlas.tools
	torf-cli
	xkcdpass
)
if [[ "$OSTYPE" == "darwin"* ]]; then
	pip3 config set global.break-system-packages true
	pip3 config set global.user true
fi
pip3 install -U "${PKGS[@]}"
