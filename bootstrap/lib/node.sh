#!/usr/bin/env bash

set -euo pipefail

PKGS=(
	fast-cli
	firebase-tools
	http-echo-server
	lighthouse
	tonal
)
if [[ "$OSTYPE" == "darwin"* ]]; then
	PKGS+=(apple-photos-mcp)
fi
PREFIX="$HOME/.npm-packages"
# Reinstalling an up-to-date package wipes state kept in its directory.
outdated="$(npm outdated --global --parseable --prefix "$PREFIX" || true)"
todo=()
for pkg in "${PKGS[@]}"; do
	if [[ ! -d "$PREFIX/lib/node_modules/$pkg" ]] ||
		grep -qF "/node_modules/$pkg:" <<<"$outdated"; then
		todo+=("$pkg@latest")
	fi
done
if ((${#todo[@]})); then
	npm install --global --prefix "$PREFIX" "${todo[@]}"
fi
