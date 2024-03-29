#!/usr/bin/env bash
# shellcheck disable=SC2086

################################################################################
# Global variables.
################################################################################

_NAME=$(command basename "$0")
CURL_ARGS="-sSq --connect-timeout 2 --max-time 5 -fL"
HELP_DOC="Set up dot files.

Usage:
  $_NAME [options]

Options:
  --all               Install all dot files.
  --bin               Install binary files.
  --bash              Install Bash dot files.
  --curl              Install Curl config file.
  --editline          Install Editline config file.
  --fasd              Install Fasd config file.
  --git               Install Git config file.
  --help              Print help.
  --mitmproxy         Install Mitmproxy config file.
  --node              Install NPM config file.
  --python            Install Python config file.
  --readline          Install Readline config file.
  --ripgrep           Install Ripgrep config file.
  --screen            Install Screen config file.
  --skip-existing     Skip installing the dot file if it already exists locally.
  --ssh               Install Ssh config file.
  --tmux              Install Tmux config file.
  --vim               Install Vim config files."
TARGET_DIR="$HOME"

################################################################################
# Helper methods.
################################################################################

# Usage:
#       check_if_installed <binary>
check_if_installed() {
	builtin hash "$1" 2>/dev/null || error "please install '$1' ($2)" 69 # EX_UNAVAILABLE
}

# Usage:
#       error <message> [<exit_code>]
error() {
	[[ $2 -eq 0 ]] && std_err_or_out=1 || std_err_or_out=2
	builtin echo "$_NAME: $1" >&"$std_err_or_out"
	exit "${2:-1}"
}

################################################################################
# Validate input.
################################################################################

for arg in "$@"; do
	case "$arg" in
	--all)
		INSTALL_ALL=1
		;;
	--bash)
		INSTALL_BASH=1
		;;
	--bin)
		INSTALL_BIN=1
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
	--node)
		INSTALL_NODE=1
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
		builtin echo "$HELP_DOC" >&2 && exit 64 # EX_USAGE
		;;
	esac
done

[[ $# -eq 0 ]] && builtin echo "$HELP_DOC" >&2 && exit 64 # EX_USAGE
[[ $HELP == 1 ]] && builtin echo "$HELP_DOC" && exit
check_if_installed "rsync" "https://github.com/WayneD/rsync"

################################################################################
# Execute.
################################################################################

builtin cd "$(dirname "$0")" || error "unable to cd into $(dirname "$0")"
SOURCE=""
EXCLUDE_FILES="--exclude=README.md"
[[ $SKIP_EXISTING == 1 ]] && OVERWRITE_SETTINGS="--ignore-existing" || OVERWRITE_SETTINGS="--backup --suffix=.bak"
if [[ $INSTALL_ALL == 1 ]]; then
	INSTALL_BASH=1
	INSTALL_BIN=1
	INSTALL_CURL=1
	INSTALL_EDITLINE=1
	INSTALL_FASD=1
	INSTALL_GIT=1
	INSTALL_NODE=1
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
[[ $INSTALL_BIN == 1 ]] && SOURCE+=" ./.local/bin/*"
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
command rsync -avhLK --relative $OVERWRITE_SETTINGS $EXCLUDE_FILES $SOURCE "$TARGET_DIR"

if [[ $INSTALL_FASD == 1 ]]; then
	check_if_installed "curl" "https://github.com/curl/curl"
	command curl $CURL_ARGS -o "$HOME/.local/bin/fasd" --create-dirs "https://raw.githubusercontent.com/clvv/fasd/master/fasd" &&
		command chmod 755 "$HOME/.local/bin/fasd"
fi
if [[ $INSTALL_NODE == 1 ]]; then
	check_if_installed "npm" "https://github.com/npm/cli"
	command npm config set fund false
	command npm config set prefix "$HOME/.npm-packages"
fi
if [[ $INSTALL_VIM == 1 ]]; then
	check_if_installed "curl" "https://github.com/curl/curl"
	check_if_installed "vim" "https://github.com/vim/vim"
	command curl $CURL_ARGS -o "$TARGET_DIR/.vim/autoload/plug.vim" --create-dirs \
		"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
	command vim +PlugInstall +qall
fi
if [[ $INSTALL_SSH == 1 ]]; then
	command chmod 700 "$TARGET_DIR"
	command chmod 700 "$TARGET_DIR/.ssh"
	command chmod 644 "$TARGET_DIR/.ssh/config"
fi
