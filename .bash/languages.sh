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
export PATH="$HOME/.local/bin:$PATH"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"
