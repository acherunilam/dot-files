#!/usr/bin/env bash

set -euo pipefail

PKGS=(
	htmlq
	ttl
)
export PATH="$HOME/.cargo/bin:$PATH"
if ! type -P cargo &>/dev/null; then
	PATH="$(brew --prefix rustup)/bin:$PATH"
	rustup update stable
	rustup default stable
fi
cargo install "${PKGS[@]}"
