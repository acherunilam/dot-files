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
	tvnamer
	xkcdpass
)
pip3 install -U "${PKGS[@]}"
