#!/usr/bin/env bash
# shellcheck disable=SC2086

################################################################################
# Global variables
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
  --ssh               Install SSH config file.
  --tmux              Install Tmux config file.
  --vim               Install Vim config files."
TARGET_DIR="$HOME"

################################################################################
# Helper methods
################################################################################

# Usage:
#       install_if_missing <binary>
install_if_missing() {
	if ! builtin hash "$1" 2>/dev/null; then
		if [[ "$OSTYPE" == "darwin"* ]]; then
			brew install "$1"
		else
			sudo dnf install --assumeyes "$1"
		fi
		# shellcheck disable=SC2181
		[[ $? -ne 0 ]] && error "unable to install $1"
	fi
}

# Usage:
#       error <message> [<exit_code>]
error() {
	[[ $2 -eq 0 ]] && std_err_or_out=1 || std_err_or_out=2
	builtin echo "$_NAME: $1" >&"$std_err_or_out"
	exit "${2:-1}"
}

################################################################################
# Validate input
################################################################################

install_if_missing "git"
install_if_missing "rsync"

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

if [[ "$OSTYPE" == "darwin"* ]]; then
	! command -v brew >/dev/null &&
		env INTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -p /dev/stdin ]]; then
	[[ $# -eq 0 ]] && INSTALL_ALL=1
	TMP_DIR="$(command mktemp -d)"
	command git clone https://github.com/acherunilam/dot-files "$TMP_DIR"
	builtin cd "$TMP_DIR" || error "unable to cd into $TMP_DIR"
else
	[[ $# -eq 0 ]] && builtin echo "$HELP_DOC" >&2 && exit 64 # EX_USAGE
	builtin cd "$(dirname "$0")" || error "unable to cd into $(dirname "$0")"
fi
[[ $HELP == 1 ]] && builtin echo "$HELP_DOC" && exit

################################################################################
# Execute
################################################################################

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

if [[ $INSTALL_BASH == 1 ]] && [[ "$OSTYPE" == "darwin"* ]]; then
	command brew list | command grep ^bash$ >/dev/null || command brew install bash
fi
if [[ $INSTALL_FASD == 1 ]]; then
	install_if_missing "curl"
	command curl $CURL_ARGS -o "$HOME/.local/bin/fasd" --create-dirs "https://raw.githubusercontent.com/clvv/fasd/master/fasd" &&
		command chmod 755 "$HOME/.local/bin/fasd"
fi
if [[ $INSTALL_NODE == 1 ]]; then
	command sed -Ei '/^(fund|prefix)=/d' "$HOME/.npmrc" 2>/dev/null
	builtin echo -e "fund=false\nprefix=$HOME/.npm-packages" >>"$HOME/.npmrc"
fi
if [[ $INSTALL_VIM == 1 ]]; then
	install_if_missing "curl"
	install_if_missing "vim"
	command curl $CURL_ARGS -o "$TARGET_DIR/.vim/autoload/plug.vim" --create-dirs \
		"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
	command vim +PlugInstall +qall
fi
if [[ $INSTALL_SSH == 1 ]]; then
	command chmod 700 "$TARGET_DIR"
	command chmod 700 "$TARGET_DIR/.ssh"
	command chmod 644 "$TARGET_DIR/.ssh/config"
fi
