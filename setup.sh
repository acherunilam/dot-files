#!/usr/bin/env bash
# shellcheck disable=SC2086


# Set up dot files.
#
# Dependencies:
#       sudo dnf install -y curl rsync vim


BASENAME=$(basename "$0")
CURL_OPTS="-sSq --connect-timeout 2 --max-time 5 -fL"
TARGET_DIR="$HOME"
USAGE="Usage: $BASENAME [OPTIONS]
A wrapper script to install the dot files present in this repo. Backups for
existing dot files will be taken prior to copying this over.

--all               install all dot files
--bash              install the bash dot files
--curl              install the curl config file
--editline          install the editline config file
--fasd              install the fasd config file
--git               install the git config file
--help              print this help
--mitmproxy         install the mitmproxy config file
--python            install the python config file
--readline          install the readline config file
--ripgrep           install the ripgrep config file
--screen            install the screen config file
--skip-existing     skip installing the dot file if it already exists locally
--ssh               install the ssh config file
--tmux              install the tmux config file
--vim               install the vim config files"


function print_usage_and_exit() {
    echo "$USAGE"
    exit ${1:-0}
}

function check_if_installed() {
    if ! type -P "$1" 1>/dev/null ; then
        echo "$BASENAME: '$1' is not installed" >&2
        exit 1
    fi
}


for arg in "$@"; do
    case "$arg" in
    --all)
        INSTALL_ALL=1
        ;;
    --bash)
        INSTALL_BASH=1
        ;;
    --curl)
        INSTALL_CURL=1
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
    --mitmproxy)
        INSTALL_MITMPROXY=1
        ;;
    --python)
        INSTALL_PYTHON=1
        ;;
    --readline)
        INSTALL_READLINE=1
        ;;
    --ripgrep)
        INSTALL_RIPGREP=1
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
        print_usage_and_exit 1 >&2
        ;;
    esac
done
[[ $# -eq 0 ]] && print_usage_and_exit 1 >&2
[[ $HELP == 1 ]] && print_usage_and_exit


cd "$(dirname "$0")" || exit 1
SOURCE=""
EXCLUDE_FILES=""
[[ $SKIP_EXISTING == 1 ]] && OVERWRITE_SETTINGS="--ignore-existing" || OVERWRITE_SETTINGS="--backup --suffix=.bak"
if [[ $INSTALL_ALL == 1 ]] ; then
    INSTALL_BASH=1
    INSTALL_CURL=1
    INSTALL_EDITLINE=1
    INSTALL_FASD=1
    INSTALL_GIT=1
    INSTALL_MITMPROXY=1
    INSTALL_PYTHON=1
    INSTALL_READLINE=1
    INSTALL_RIPGREP=1
    INSTALL_SCREEN=1
    INSTALL_SSH=1
    INSTALL_TMUX=1
    INSTALL_VIM=1
fi
[[ $INSTALL_BASH == 1 ]] && SOURCE+=" ./.bashrc ./.bash_profile ./.bash/*.sh"
[[ $INSTALL_CURL == 1 ]] && SOURCE+=" ./.curlrc"
[[ $INSTALL_EDITLINE == 1 ]] && SOURCE+=" ./.editrc"
[[ $INSTALL_FASD == 1 ]] && SOURCE+=" ./.fasdrc"
[[ $INSTALL_GIT == 1 ]] && SOURCE+=" ./.gitconfig"
[[ $INSTALL_MITMPROXY == 1 ]] && SOURCE+=" ./.mitmproxy/*.yaml"
[[ $INSTALL_PYTHON == 1 ]] && SOURCE+=" ./.pythonrc"
[[ $INSTALL_READLINE == 1 ]] && SOURCE+=" ./.inputrc"
[[ $INSTALL_RIPGREP == 1 ]] && SOURCE+=" ./.ripgreprc"
[[ $INSTALL_SCREEN == 1 ]] && SOURCE+=" ./.screenrc"
[[ $INSTALL_SSH == 1 ]] && SOURCE+=" ./.ssh"
[[ $INSTALL_TMUX == 1 ]] && SOURCE+=" ./.tmux.conf"
[[ $INSTALL_VIM == 1 ]] && SOURCE+=" ./.vimrc"
[[ "$OSTYPE" != "darwin"* ]] && EXCLUDE_FILES+=" --exclude=mac.sh"
check_if_installed "rsync"
command rsync -avhLK --relative $OVERWRITE_SETTINGS $EXCLUDE_FILES $SOURCE "$TARGET_DIR"

if [[ $INSTALL_FASD == 1 ]] ; then
    check_if_installed "curl"
    command curl $CURL_OPTS -o "$HOME/.local/bin/fasd" --create-dirs "https://raw.githubusercontent.com/clvv/fasd/master/fasd" \
        && command chmod 755 "$HOME/.local/bin/fasd"
fi

if [[ $INSTALL_VIM == 1 ]] ; then
    check_if_installed "curl"
    command curl $CURL_OPTS -o "$TARGET_DIR/.vim/autoload/plug.vim" --create-dirs \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    check_if_installed "vim"
    command vim +PlugInstall +qall
fi


if [[ $INSTALL_SSH == 1 ]] ; then
    command chmod 700 "$TARGET_DIR"
    command chmod 700 "$TARGET_DIR/.ssh"
    command chmod 644 "$TARGET_DIR/.ssh/config"
fi
