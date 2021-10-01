# shellcheck disable=SC2155


# Golang
export GOPATH="$HOME/go"
if [[ "$OSTYPE" == "linux"* ]] ; then
    export PATH="$PATH:/usr/local/go/bin"
elif [[ "$OSTYPE" == "darwin"* ]] ; then
    export PATH="$PATH:$BREW_PREFIX/opt/go/libexec/bin"
fi
export PATH="$PATH:$GOPATH/bin"


# Java
if [[ "$OSTYPE" == "linux"* ]] ; then
    export JAVA_HOME=$(
        command find "/usr/lib/jvm" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | \
            command sort -nr -t'-' -k2 | command head -n1
    )
elif [[ "$OSTYPE" == "darwin"* ]] ; then
    export JAVA_HOME=$(/usr/libexec/java_home)
fi


# Python
export PYTHONSTARTUP="$HOME/.pythonrc"
if [[ "$OSTYPE" == "linux"* ]] ; then
    export PATH="$HOME/miniconda3/bin:$PATH"
elif [[ "$OSTYPE" == "darwin"* ]] ; then
    export PATH="/opt/miniconda3/bin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"


# Rust
export PATH="$HOME/.cargo/bin:$PATH"
