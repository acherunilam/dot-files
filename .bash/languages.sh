# shellcheck shell=bash
# shellcheck disable=SC2155


# Java
if [[ "$OSTYPE" == "linux"* ]] ; then
    export JAVA_HOME="$(command readlink -f "$(type -p java)" | command sed 's/bin\/java$//g')"
elif [[ "$OSTYPE" == "darwin"* ]] ; then
    export JAVA_HOME=$(/usr/libexec/java_home)
fi


# Python
export PYTHONSTARTUP="$HOME/.pythonrc"
if [[ "$OSTYPE" == "linux"* ]] ; then
    export PATH="$HOME/miniconda3/bin:$PATH"
elif [[ "$OSTYPE" == "darwin"* ]] ; then
    export PATH="$(command brew --caskroom)/miniconda/base/bin:$PATH"
fi


# Rust
export PATH="$HOME/.cargo/bin:$PATH"
