#!/usr/bin/env bash

PKGS=(
	fast-cli
	firebase-tools
	http-echo-server
	lighthouse
	tonal
)
npm install --global --prefix "$HOME/.npm-packages" "${PKGS[@]}"
