#!/usr/bin/env bash

PKGS=(
	htmlq
	ttl
)
command -v cargo &>/dev/null || rustup-init -y
cargo install "${PKGS[@]}"
