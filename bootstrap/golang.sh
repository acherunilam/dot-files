#!/usr/bin/env bash


PKGS=(
    github.com/danielgatis/imgcat
)
go install "${PKGS[@]/%/@latest}"
