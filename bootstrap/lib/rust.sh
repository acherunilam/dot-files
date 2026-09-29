#!/usr/bin/env bash

set -euo pipefail

PKGS=(
	htmlq
	ttl
)
export PATH="$HOME/.cargo/bin:$PATH"
if ! command -v cargo &>/dev/null; then
	PATH="$(brew --prefix rustup)/bin:$PATH"
	rustup default stable
fi
cargo install "${PKGS[@]}"
