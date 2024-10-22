#!/usr/bin/env bash

PKGS=(
	bashplotlib
	black
	blaeu
	censys
	cinemagoer
	ffsubsync
	hashid
	Pillow
	ripe.atlas.tools
	torf-cli
	xkcdpass
)
pip3 install -U "${PKGS[@]}"
