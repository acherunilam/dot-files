#!/usr/bin/env bash


PKGS=(
    github.com/danielgatis/imgcat
    github.com/hakluke/haktrails
    github.com/ipinfo/cli/ipinfo
    github.com/ipinfo/mmdbctl
)
go install "${PKGS[@]/%/@latest}"
