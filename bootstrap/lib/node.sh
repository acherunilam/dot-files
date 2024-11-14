#!/usr/bin/env bash

PKGS=(
	fast-cli
  firebase-tools
	http-echo-server
	lighthouse
)
npm install --global "${PKGS[@]}"
