#!/usr/bin/env bash

PKGS=(
	fast-cli
	firebase-tools
	http-echo-server
	lighthouse
	tonal
)
npm install --global "${PKGS[@]}"
