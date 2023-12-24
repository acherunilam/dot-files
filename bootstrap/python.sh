#!/usr/bin/env bash


PKGS=(
    bashplotlib
    black
    blaeu
    censys
    cinemagoer
    ffsubsync
    hashid
    ripe.atlas.tools
    xkcdpass
)
pip3 install "${PKGS[@]}"
