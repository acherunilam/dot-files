#!/usr/bin/env bash


PKGS=(
    bashplotlib
    blaeu
    ffsubsync
    ripe.atlas.tools
    xkcdpass
    yq
)
pip3 install "${PKGS[@]}"
