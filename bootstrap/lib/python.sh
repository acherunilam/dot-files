#!/usr/bin/env bash

set -euo pipefail

LIBS=(
	imdbinfo
	imdbinfo-aws
)
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
TOOLS_PRE=(
	# Plugins and --source need the 1.6 beta.
	'comictagger[cbr]'
)
if [[ "$OSTYPE" == "darwin"* ]]; then
	pip3 config set global.break-system-packages true
	pip3 config set global.user true
	PKG_CONFIG_PATH="$(brew --prefix icu4c)/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
	export PKG_CONFIG_PATH
fi
pip3 install -U "${LIBS[@]}"
pipx upgrade --install "${TOOLS[@]}"
pipx upgrade --install --pip-args=--pre "${TOOLS_PRE[@]}"
