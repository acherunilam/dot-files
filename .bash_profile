# shellcheck disable=SC1090,SC2148


# This file is read and executed only when Bash is invoked as an interactive
# login shell.
[[ -f ~/.bashrc && -z $_BASHRC_LOADED ]] && source ~/.bashrc
