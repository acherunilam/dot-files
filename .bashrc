# shellcheck disable=SC1090,SC1091,SC2016,SC2148,SC2154


# This file is read and executed only when Bash is invoked as an interactive
# non-login shell. If not running interactively, don't do anything.
[[ $- != *i* ]] && return
_BASHRC_LOADED=1


# Add the following locations to $PATH if not already present.
path_list=(
    "/bin"
    "/sbin"
    "/usr/bin"
    "/usr/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
    "$HOME/.local/bin"
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
PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND%;};}"
PROMPT_COMMAND+='repo_state="$(__git_ps1 "<%s>" 2>/dev/null)$(__hg_ps1 "<%s>" 2>/dev/null)"'
# Show how long the last command took (if 5s or more) and its exit code (if
# non-zero). It must run first in PROMPT_COMMAND, before anything resets $?.
if (( BASH_VERSINFO[0] >= 5 )) ; then
    PS0='${EPOCHREALTIME:0:$((_cmd_start=${EPOCHREALTIME//[.,]/},0))}'
    _prompt_status() {
        local rc=$? secs
        prompt_status=''
        [[ -z $_cmd_start ]] && return
        secs=$(( (${EPOCHREALTIME//[.,]/} - _cmd_start) / 1000000 ))
        unset _cmd_start
        if (( secs >= 3600 )) ; then
            printf -v prompt_status ' %dh%02dm' $((secs / 3600)) $((secs % 3600 / 60))
        elif (( secs >= 60 )) ; then
            printf -v prompt_status ' %dm%02ds' $((secs / 60)) $((secs % 60))
        elif (( secs >= 5 )) ; then
            prompt_status=" ${secs}s"
        fi
        (( rc )) && prompt_status+=$' \001\e[1;31m\002['"$rc"$']\001\e[0m\002'
    }
    PROMPT_COMMAND="_prompt_status${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
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
PS1+='\[\033[1;33m\]$repo_state'        # git/hg branch
PS1+='\[\033[0m\]$prompt_status'        # duration and exit code
PS1+='\[\033[0m\]'${SENTINEL_CHAR}' '
PS4='+ $EPOCHREALTIME\011(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
# Set the MySQL prompt.
export MYSQL_PS1="\u@\h [\d]> "


# Auto-attach to Tmux (https://github.com/tmux/tmux) when you SSH.
#
# Dependencies:
#       dnf install tmux
[[ -n $SSH_CONNECTION ]] && [[ -z $TMUX ]] && [[ -z $DONT_TMUX_ATTACH ]] && tmux attach &>/dev/null
