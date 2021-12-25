# shellcheck disable=SC1090,SC1091,SC2148,SC2154


# This file is read and executed only when Bash is invoked as an interactive
# non-login shell. If not running interactively, don't do anything.
[[ $- != *i* ]] && return


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


# Load Git/Mercurial repository-related info for the Bash prompt.
export GIT_PS1_SHOWDIRTYSTATE=true HG_PS1_SHOWDIRTYSTATE=true
PROMPT_COMMAND+='; repo_state="$(__git_ps1 "<%s>" 2>/dev/null)$(__hg_ps1 "<%s>" 2>/dev/null)"'
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
PS1+='\[\033[1;33m\]$repo_state'        # git/hg branch
PS1+='\[\033[0m\]'${SENTINEL_CHAR}' '
PS4='+ $EPOCHREALTIME\011(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
# Set the MySQL prompt.
export MYSQL_PS1="\u@\h [\d]> "
