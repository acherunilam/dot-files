# shellcheck shell=bash

# Golang
export PATH="$HOME/go/bin:$PATH"

# Node
export NPM_PACKAGES="$HOME/.npm-packages"
export NODE_PATH="$NPM_PACKAGES/lib/node_modules:$NODE_PATH"
export PATH="$NPM_PACKAGES/bin:$PATH"
export MANPATH="$NPM_PACKAGES/share/man:$MANPATH"

# Python
export PYTHONSTARTUP="$HOME/.pythonrc"
for dir in $(command find "$HOME/Library/Python" -maxdepth 2 -type d -name bin 2>/dev/null); do
	export PATH="$dir:$PATH"
done

# Rust
export PATH="$HOME/.cargo/bin:$PATH"
