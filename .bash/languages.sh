# shellcheck shell=bash
# shellcheck disable=SC2155


# Golang
export PATH="$HOME/go/bin:$PATH"


# Python
export PYTHONSTARTUP="$HOME/.pythonrc"
if [[ "$OSTYPE" == "linux"* ]] ; then
    export PATH="$HOME/miniconda3/bin:$PATH"
elif [[ "$OSTYPE" == "darwin"* ]] ; then
    export PATH="$BREW_PREFIX/Caskroom/miniconda/base/bin:$PATH"
fi


# Rust
export PATH="$HOME/.cargo/bin:$PATH"
