#!/usr/bin/env bash


PKGS=(
    bashplotlib
    blaeu
    censys
    ffsubsync
    ripe.atlas.tools
    xkcdpass
)
pip3 install "${PKGS[@]}"
