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
	xkcdpass
)
pip3 install -Uq "${PKGS[@]}"
