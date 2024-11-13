#!/usr/bin/env bash

PKGS=(
	htmlq
)
command -v cargo &>/dev/null || rustup-init -y
cargo install "${PKGS[@]}"
