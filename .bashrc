# shellcheck disable=SC1090,SC1091,SC2015,SC2148,SC2154


# This file is read and executed only when Bash is invoked as an interactive
# non-login shell. If not running interactively, don't do anything.
[[ $- != *i* ]] && return


# Enable Bash completion.
[[ -f "/usr/share/bash-completion/bash_completion" ]] \
    && source "/usr/share/bash-completion/bash_completion"
# Add the following locations to $PATH if not already present.
path_list=(
    "/bin"
    "/sbin"
    "/usr/bin"
    "/usr/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
    "$HOME/bin"
)
for p in "${path_list[@]}" ; do
    [[ ":$PATH:" != *":$p:"* ]] && PATH="$p:${PATH}"
done
# Load all the Bash configs.
for file in "$HOME"/.bash/*.sh ; do
    [[ -f "$file" ]] && source "$file"
done


# Enable color support for ls.
[[ -r ~/.dircolors ]] && eval "$(command dircolors -b ~/.dircolors)" || eval "$(command dircolors -b)"
# Load Git repository-related info for the Bash prompt.
if type -t __git_ps1 >/dev/null ; then
    export GIT_PS1_SHOWDIRTYSTATE=true
    PROMPT_COMMAND+='; git_state=$(__git_ps1 "<%s>")'
fi
# Set the Bash prompt.
USERNAME_COLOR='\[\033[1;34m\]'         # blue
SENTINEL_CHAR='$'
if [[ -f "/.dockerenv" ]] ; then        # inverted blue
    CONTAINER='\[\033[1;104m\](docker)\[\033[0m\] '
elif [[ $USER == 'root' ]] ; then       # yellow
    USERNAME_COLOR='\[\033[1;33m\]'
    SENTINEL_CHAR='#'
elif [[ -n $SSH_CONNECTION ]] ; then    # red
    USERNAME_COLOR='\[\033[1;31m\]'
fi
PS1=${CONTAINER}
PS1+=${USERNAME_COLOR}'\u'              # user
PS1+='\[\033[0m\]\[\033[1;32m\]@\h'     # hostname
PS1+='\[\033[0m\]:\[\033[1;34m\]\w'     # working directory
PS1+='\[\033[1;33m\]$git_state'         # git branch
PS1+='\[\033[0m\]'${SENTINEL_CHAR}' '
PS4='+ $EPOCHREALTIME\011(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
# Set the MySQL prompt.
export MYSQL_PS1="\u@\h [\d]> "


# When over SSH, attach to Tmux right away.
[[ -n $SSH_CONNECTION ]] && [[ -z $TMUX ]] && [[ -z $DONT_TMUX_ATTACH ]] && tmux attach &>/dev/null


# Load custom key bindings for the shell.
export INPUTRC="$HOME/.inputrc"
# Set default text editor.
export EDITOR="vim"
# Make `less` more friendly for non-text input files.
export LESSOPEN="|lesspipe.sh %s"
# Enable color support for `less`. Also, search within is case insensitive
# unless the pattern contains uppercase letters.
export LESS="-Ri"
