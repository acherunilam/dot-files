#!/usr/bin/env bash


PKGS=(
    ffsubsync
    ripe.atlas.tools
    xkcdpass
    yq
)
sudo pip3 install "${PKGS[@]}"
