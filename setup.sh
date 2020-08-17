#!/usr/bin/env bash

BASENAME=$(basename "$0")
USAGE="Usage: $BASENAME [OPTIONS]
A wrapper script to install the dot files present in this repo. Backups for
existing dot files will be taken prior to copying this over.

--all               install all dot files
--bash              install the bash dot files
--editline          install the editline config file
--fasd              install the fasd config file
--git               install the git config file
--help              print this help
--readline          install the readline config file
--screen            install the screen config file
--skip-existing     skip installing the dot file if it already exists locally
--ssh               install the ssh config file
--tmux              install the tmux config file
--vim               install the vim config files
"

print_usage_and_exit() {
    echo "$USAGE"
    exit ${1:-0}
}

for arg in "$@"; do
    case "$arg" in
    --all)
        INSTALL_ALL=1
        ;;
    --bash)
        INSTALL_BASH=1
        ;;
    --editline)
        INSTALL_EDITLINE=1
        ;;
    --fasd)
        INSTALL_FASD=1
        ;;
    --git)
        INSTALL_GIT=1
        ;;
    --help)
        HELP=1
        ;;
    --readline)
        INSTALL_READLINE=1
        ;;
    --skip-existing)
        SKIP_EXISTING=1
        ;;
    --screen)
        INSTALL_SCREEN=1
        ;;
    --ssh)
        INSTALL_SSH=1
        ;;
    --tmux)
        INSTALL_TMUX=1
        ;;
    --vim)
        INSTALL_VIM=1
        ;;
    *)
        print_usage_and_exit 1
        ;;
    esac
done

[[ $HELP == 1 || "$#" -eq 0 ]] && print_usage_and_exit

# TODO: check for rsync
# TODO: check for recursive clone
# TODO: check for fd-find
# TODO: check for fzf
SRC_DIR="$(dirname "$0")"
SOURCE=""
TARGET="$HOME"
EXCLUDE_FILES=""
[[ "$OSTYPE" != "darwin"* ]] && EXCLUDE_FILES+=" --exclude=mac.bash"
[[ $SKIP_EXISTING == 1 ]] && OVERWRITE_SETTINGS="--ignore-existing" || OVERWRITE_SETTINGS="--backup --suffix=.bak"
if [[ $INSTALL_ALL == 1 ]] ; then
    INSTALL_BASH=1
    INSTALL_EDITLINE=1
    INSTALL_FASD=1
    INSTALL_GIT=1
    INSTALL_READLINE=1
    INSTALL_SCREEN=1
    INSTALL_SSH=1
    INSTALL_TMUX=1
    INSTALL_VIM=1
fi
[[ $INSTALL_BASH == 1 ]] && SOURCE+=" $SRC_DIR/.bashrc $SRC_DIR/.bash_profile $SRC_DIR/.bash/*.bash"
[[ $INSTALL_EDITLINE == 1 ]] && SOURCE+=" $SRC_DIR/.editrc"
[[ $INSTALL_FASD == 1 ]] && SOURCE+=" $SRC_DIR/.fasdrc"
[[ $INSTALL_GIT == 1 ]] && SOURCE+=" $SRC_DIR/.gitconfig"
[[ $INSTALL_READLINE == 1 ]] && SOURCE+=" $SRC_DIR/.inputrc"
[[ $INSTALL_SCREEN == 1 ]] && SOURCE+=" $SRC_DIR/.screenrc"
[[ $INSTALL_SSH == 1 ]] && SOURCE+=" $SRC_DIR/.ssh"
[[ $INSTALL_TMUX == 1 ]] && SOURCE+=" $SRC_DIR/.tmux.conf"
[[ $INSTALL_VIM == 1 ]] && SOURCE+=" $SRC_DIR/.vimrc"
rsync -avzh --copy-links --relative $OVERWRITE_SETTINGS $EXCLUDE_FILES $SOURCE "$TARGET"

if [[ $INSTALL_SSH == 1 ]]; then
    chmod 700 "$TARGET/.ssh"
    chmod 644 "$TARGET/.ssh/config"
fi
if [[ $INSTALL_VIM == 1 ]]; then
    # TODO: check for vim
    curl --silent -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +qall
fi
