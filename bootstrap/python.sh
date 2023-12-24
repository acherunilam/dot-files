#!/usr/bin/env bash


PKGS=(
    bashplotlib
    blaeu
    censys
    ffsubsync
    hashid
    ripe.atlas.tools
    xkcdpass
)
pip3 install "${PKGS[@]}"
