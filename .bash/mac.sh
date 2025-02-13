# shellcheck shell=bash
# shellcheck disable=SC1091,SC2139,SC2155

[[ "$OSTYPE" != "darwin"* ]] && return

# Load Homebrew (https://brew.sh), a package management system.
export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH+:$PATH}"
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
include "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
for file in "$HOMEBREW_PREFIX/etc/bash_completion.d/"*; do
	include "$file"
done

# Preview the colors here (https://geoff.greer.fm/lscolors).
export CLICOLOR=1
export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD

# Load John the Ripper (https://www.openwall.com/john), a password security
# auditing and password recovery tool.
export PATH="$HOMEBREW_PREFIX/share/john/:$PATH"

# Load Metasploit (https://github.com/rapid7/metasploit-framework), a
# penetration testing framework.
export PATH="/opt/metasploit-framework/bin:$PATH"

# Load Secretive (https://github.com/maxgoedjen/secretive), a Secure
# Enclave-based SSH Agent.
# export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
# export PATH="$HOMEBREW_PREFIX/opt/openssh/bin:$PATH"

# Make macOS more like Linux.
export PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"
export PATH="$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/opt/findutils/libexec/gnuman:$MANPATH"
export PATH="$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnubin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnuman:$MANPATH"
export PATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnuman:$MANPATH"
export PATH="$HOMEBREW_PREFIX/opt/util-linux/bin:$PATH"
alias awk='gawk'                                                    # `awk -vFPAT` should work
alias base64='gbase64'                                              # `base64 -w0` should work
alias date='gdate'                                                  # `date -I` should work
alias head='ghead'                                                  # `head -n0` should work
alias osv='sw_vers'                                                 # output macOS system version
alias paste='gpaste'                                                # `paste -sd' '` should work
alias port='sudo lsof -nP -iudp -itcp -stcp:listen | grep -v ":\*"' # show all ports listening for connections
alias tac='gtac'                                                    # BSD doesn't have tac
alias wc='gwc'                                                      # `wc -l` should not having leading whitespace

# Run with elevated privileges by default.
alias dtruss='sudo dtruss'
alias mtr='sudo mtr'

# Helpers.
alias dark='brightness 0 2>/dev/null'    # set display brightness to 0
alias inv='mogrify -channel RGB -negate' # invert colors for the image
alias lck='pmset displaysleepnow'        # switch off display
alias loc='mdfind -name 2>/dev/null'     # search globally by file name
alias shred='gshred -vfzu -n 10'         # securely erase the file
alias slp='pmset sleepnow'               # go to sleep

# Shutdown or reboot immediately.
#
# Usage:
#       bye [-r]
#
# Options:
#       -r      Reboot instead of shutting down.
bye() {
	local mode="${1:--h}"
	[[ $# -le 1 ]] && sudo command shutdown "$mode" now || return 1
}

# cd into the directory that is currently open in Finder.
#
# Usage:
#       cdf
cdf() {
	local target="$(
		osascript -e "tell application \"Finder\" to if (count of Finder \
            windows) > 0 then get POSIX path of (target of front Finder \
            window as text)" 2>/dev/null
	)"
	if [[ -n $target ]]; then
		cd "$target" || return 1
	else
		error "no Finder window found" 2
		return
	fi
}

# Delete all small (>10M) downloaded files.
#
# Usage:
#       clean [-n]
#
# Options:
#       -n      Dry run.
clean() {
	local SIZE_LIMIT="10M"
	local cmd="command find $HOME/Downloads/ -maxdepth 1 -type f \
        -size -$SIZE_LIMIT ! -name '.DS_Store' ! -name '*.crdownload' \
        ! -name '*.aria2'"
	[[ "$1" != "-n" ]] && cmd+=" -exec rm -v {} +"
	eval "$cmd" | command sed -E "s/^${HOME//\//\\/}\/Downloads\///g"
}

# Clear all recent files accessed through the GUI and CLI.
#
# Usage:
#       clear-history
#
# Environment variables:
#       export CLEAR_HISTORY_KEYWORDS="<keyword1>:<keyword2>"
#
# shellcheck disable=SC2015
clear-history() {
	# Clear recent files.
	osascript -e "tell application \"System Events\" to click menu item \
            \"Clear Menu\" of menu of menu item \"Recent Items\" of menu of \
            menu bar item \"Apple\" of menu bar of process \"Finder\"" \
		1>/dev/null ||
		error "unable to clear recent files"
	# Clear recent folders.
	osascript -e "tell application \"System Events\" to click menu item \
            \"Clear Menu\" of menu of menu item \"Recent Folders\" of menu of \
            menu bar item \"Go\" of menu bar of process \"Finder\"" \
		1>/dev/null ||
		error "unable to clear recent folders"
	# Clear 'Go to' Folder.
	defaults delete com.apple.finder GoToField &>/dev/null
	defaults delete com.apple.finder GoToFieldHistory &>/dev/null
	killall "Finder" || error "unable to clear Go to Folder"
	# Clear VLC's recent files.
	osascript -e "tell application \"VLC\" to activate" 1>/dev/null &&
		osascript -e "tell application \"Finder\" to set visible of process \
            \"VLC\" to false" 1>/dev/null &&
		osascript -e "tell application \"System Events\" to click menu item \
            \"Clear Menu\" of menu of menu item \"Open Recent\" of menu of menu \
            bar item \"File\" of menu bar 1 of process \"VLC\"" 1>/dev/null &&
		killall "VLC" ||
		error "unable to clear recent VLC files"
	if [[ -n "$CLEAR_HISTORY_KEYWORDS" ]]; then
		# Clear Bash history lines containing any of the specified keywords.
		local hist_file="${HISTFILE:-$HOME/.bash_history}"
		local tmp_file="$(command mktemp)"
		echo -e "${CLEAR_HISTORY_KEYWORDS//:/\\n}" | while read -r k; do
			command tail -r "$hist_file" |
				command sed "/${k//\//\\/}/,+1d" |
				command tail -r >"$tmp_file" &&
				command cp -f "$tmp_file" "$hist_file"
		done || error "unable to clear Bash history keywords"
		# Clear Fasd paths containing any of the specified paths.
		echo -e "${CLEAR_HISTORY_KEYWORDS//:/\\n}" | while read -r p; do
			command sed -i "/${p//\//\\/}/d" "${_FASD_DATA:-$HOME/.fasd}"
		done || error "unable to clear Fasd paths"
	fi
}

# Unmount all DMGs or external HDDs.
#
# Usage:
#       eject [-e]
#
# Options:
#       -e      Unmount HDDs instead of DMGs.
eject() {
	local volume volumes disk_type label device devices
	volumes=$(command diskutil list | command grep "/dev/disk")
	[[ "$1" == "-e" ]] && disk_type='external' || disk_type='image'
	while read -r volume; do
		if command grep -q $disk_type <<<"$volume"; then
			label=$(command awk '{print $1}' <<<"$volume")
			devices+=" $label"
		fi
	done <<<"$volumes"
	for device in $devices; do
		command diskutil eject "$device"
	done
}

# Set iTerm's tab title.
#
# It works using OSC 9, an Xterm-specific escape sequence used to send terminal
# notifications (https://iterm2.com/documentation-escape-codes.html).
#
# Usage:
#       iterm-title <title>
#
# shellcheck disable=SC1003
iterm-title() {
	local output
	output="$(printf '\e]1;%s\a' "$*")"
	[[ -n "$TMUX" ]] && output="$(printf '\ePtmux;\e%s\e\\' "$output")"
	printf "%s" "$output"
}

# Move the downloaded files matching the regex into current directory.
#
# Usage:
#       mdownload [-n] [<pattern>]
#
# Options:
#       -n      Dry run.
mdownload() {
	local cmd is_dry_run
	[[ "$1" == "-n" ]] && shift && is_dry_run=1
	cmd="command find $HOME/Downloads/ -maxdepth 1 -type f -iname '*'$*'*' \
        ! -name '.DS_Store' ! -name '*.crdownload' ! -name '*.aria2'"
	[[ -z "$is_dry_run" ]] && cmd+=' -exec mv -v {} . \;'
	eval "$cmd"
}

# Read the text from an image file using Tesseract
# (https://github.com/tesseract-ocr/tesseract), an open-source OCR engine.
#
# Usage:
#       ocr <file>
ocr() {
	if [[ -z "$1" ]]; then
		local tmp_dir="$(command mktemp -d)"
		osascript -e "tell application \"System Events\" to write (the clipboard \
            as «class PNGf») to (make new file at folder \"$tmp_dir\" with properties \
            {name:\"screenshot.png\"})" 2>/dev/null
		if [[ -s "$tmp_dir/screenshot.png" ]]; then
			set -- "$tmp_dir/screenshot.png"
		else
			error "no image found in clipboard"
			return
		fi
	elif ! [[ -r "$1" ]]; then
		error "unable to open file '$1'"
		return
	fi
	local result="$(command tesseract "$1" - --tessdata-dir "$HOMEBREW_PREFIX/share/tessdata" 2>/dev/null)"
	echo "$result"
	[[ -t 1 ]] && echo -n "$result" | command pbcopy
	[[ -n "$tmp_dir" ]] && command rm "$tmp_dir/screenshot.png"
}

# Copy content as plaintext and HTML to the clipboard. Note that the plaintext
# version will automatically have its HTML tags stripped.
#
# Usage:
#       echo "this is <b>bold</b> text" | pbc
pbc() {
	local content="$(</dev/stdin)"
	local plaintext="$(echo -n "$content" | command sed 's/<[^>]*>//g')"
	local htmlbinary="$(echo -n "$content" | command xxd -p | command tr -d '\n')"
	command osascript -e "set the clipboard to {string:\"$plaintext\", \
        «class HTML»:«data HTML${htmlbinary}»}"
}

# Paste the image on your clipboard to the current directory.
#
# Usage:
#       pngpaste [<filename>]
pngpaste() {
	local filename="${1:-screenshot.png}"
	[[ $filename == *".png" ]] || filename+=".png"
	local tmp_dir="$(command mktemp -d)"
	osascript -e "tell application \"System Events\" to write (the clipboard \
        as «class PNGf») to (make new file at folder \"$tmp_dir\" with properties \
        {name:\"screenshot.png\"})" 2>/dev/null
	if [[ -s "$tmp_dir/screenshot.png" ]]; then
		command mv "$tmp_dir/screenshot.png" "$filename"
	else
		error "no image found in clipboard"
		return
	fi
}

# Scan QR code from an image file using Zbar (https://github.com/mchehab/zbar),
# an open-source bar code reader.
#
# Usage:
#       qr <file>
qr() {
	if [[ -z "$1" ]]; then
		local tmp_dir="$(command mktemp -d)"
		osascript -e "tell application \"System Events\" to write (the clipboard \
            as «class PNGf») to (make new file at folder \"$tmp_dir\" with properties \
            {name:\"screenshot.png\"})" 2>/dev/null
		if [[ -s "$tmp_dir/screenshot.png" ]]; then
			set -- "$tmp_dir/screenshot.png"
		else
			error "no image found in clipboard"
			return
		fi
	elif ! [[ -r "$1" ]]; then
		error "unable to open file '$1'"
		return
	fi
	local result="$(command zbarimg --quiet --raw "$1")"
	echo "$result"
	[[ -t 1 ]] && echo -n "$result" | command pbcopy
	[[ -n "$tmp_dir" ]] && command rm "$tmp_dir/screenshot.png"
}

# Remove extended attributes for a file downloaded from the internet.
#
# Usage:
#       whitelist
whitelist() {
	sudo command xattr -rd com.apple.metadata:kMDItemWhereFroms "$@"
	sudo command xattr -rd com.apple.quarantine "$@"
}
