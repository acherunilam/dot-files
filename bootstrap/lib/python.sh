#!/usr/bin/env bash

PKGS=(
	bashplotlib
	black
	blaeu
	cinemagoer
	ffsubsync
	hashid
	Pillow
	pycookiecheat
	ripe.atlas.tools
	torf-cli
	tvnamer
	xkcdpass
)
if [[ "$OSTYPE" == "darwin"* ]]; then
	pip3 config set global.break-system-packages true
	pip3 config set global.user true
fi
pip3 install -U "${PKGS[@]}"
