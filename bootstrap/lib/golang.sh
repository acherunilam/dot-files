#!/usr/bin/env bash

MODULES=(
	github.com/cemulus/crt
	github.com/danielgatis/imgcat
	github.com/hakluke/haktrails
	github.com/ipinfo/cli/ipinfo
	github.com/ipinfo/mmdbctl
	github.com/mikefarah/yq/v4
	mvdan.cc/sh/v3/cmd/shfmt
)
for module in "${MODULES[@]}"; do
	go install "${module/%/@latest}"
done
