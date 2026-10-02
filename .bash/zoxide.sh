# shellcheck shell=bash


# Load zoxide (https://github.com/ajeetdsouza/zoxide), a smarter cd command that
# remembers the directories you visit and jumps to them by keyword.
#
# Usage:
#       z <keyword>...
#       zz <keyword>...
#
# Dependencies:
#       dnf install fzf zoxide
if type -P zoxide >/dev/null; then
    eval "$(command zoxide init bash)"
    alias zz='zi'
fi
