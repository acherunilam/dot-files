#!/usr/bin/env bash


PKGS=(
    github.com/danielgatis/imgcat
    github.com/ipinfo/cli/ipinfo
)
go install "${PKGS[@]/%/@latest}"
