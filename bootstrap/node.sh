#!/usr/bin/env bash


PKGS=(
    fast-cli
    http-echo-server
    lighthouse
)
npm install --global "${PKGS[@]}"
