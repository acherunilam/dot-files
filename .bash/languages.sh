# shellcheck shell=bash

# Golang
prepend_path PATH "$HOME/go/bin"

# Node
export NPM_PACKAGES="$HOME/.npm-packages"
prepend_path NODE_PATH "$NPM_PACKAGES/lib/node_modules"
prepend_path PATH "$NPM_PACKAGES/bin"
prepend_path MANPATH "$NPM_PACKAGES/share/man"
[[ -n "$MANPATH" && "$MANPATH" != *: ]] && MANPATH+=":"

# Python
for dir in $(printf '%s\n' "$HOME"/Library/Python/*/bin | command sort -rV); do
	prepend_path PATH "$dir"
done

# Rust
prepend_path PATH "$HOME/.cargo/bin"
