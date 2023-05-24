#!/usr/bin/env bash


PKGS=(
    blaeu
    ffsubsync
    ripe.atlas.tools
    xkcdpass
    yq
)
pip3 install "${PKGS[@]}"
