# shellcheck shell=bash

# Move up the directory.
alias ..='cd ..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'
alias ..5='cd ../../../../..'
# Always be verbose/succinct.
alias cp='cp -v'
alias dig='dig +short'
alias mv='mv -v'
alias rm='rm -v'
# Shorten frequently used commands.
alias c='cat'
alias cl="tr '[:upper:]' '[:lower:]'"
alias cu="tr '[:lower:]' '[:upper:]'"
alias cnt='sort | uniq -c | sort -nr'
alias dni='sudo dnf install -y'
alias dnu='sudo dnf remove -y'
alias g='grep -Ei'
alias ga='git add -A'
alias gc='git checkout .'
alias gd='git diff'
alias gl='git lg'
alias gs='git status'
alias h='head -n'
alias l='less'
alias la='ls -A'                  # list all files
alias lc='wc -l'                  # count the number of lines
alias ld='ls -d */ 2>/dev/null'   # list only directories
alias lh='ls -d .??* 2>/dev/null' # list only hidden files
alias ll='ls -alFh'               # list all files with their details
alias p='pbcopy'                  # copy contents to clipboard
alias py='python3'
alias s='sort -b'
alias t='tail -n'
alias trans='trans -brief -no-warn -'
alias u='uniq'
alias x='extract' # extract the contents of an archive
# Inspect the system.
alias jcl='journalctl -f -u'        # tail systemd service logs
alias osv='cat /etc/system-release' # print the Linux distribution
alias perf='sudo perf'              # performance analysis
alias port='sudo ss -tulpn'         # show all listening ports
alias scl='sudo systemctl'          # systemd inspection
# Run with specific settings.
alias bc='sed "s/^/scale=2;/g" | bc -l'                  # floating-point precision of 2
alias mkdir='mkdir -p'                                   # create parent directory if it doesn't exist
alias pls='sudo $(history -p \!\!)'                      # re-execute last command with elevated privileges
alias rsync='rsync -avhPLK --partial-dir=.rsync-partial' # enable partial synchronization
# Colorize output.
alias diff='diff --color'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias watch='watch --color'

# Simplified awk.
#
# Example:
#       aw 1-3              Print the first 3 columns
#       aw 1-3,7            Print the first 3 columns, followed by the 7th
#       aw 1-3,7 -F":"      Same as above, but passes the -F":" option to awk
#
# shellcheck disable=SC2086
aw() {
	local ranges start end arg
	local columns=""
	local opts=""
	for arg in "$@"; do
		[[ "${arg::1}" != [0-9] ]] && opts+=" $arg" && continue
		IFS=',' read -ra ranges <<<"$arg"
		for range in "${ranges[@]}"; do
			IFS='-' read -r start end <<<"$range"
			if [[ $start =~ ^[0-9]+$ ]] && [[ $end =~ ^[0-9]*$ ]]; then
				columns+="$(command seq -s ',' -f '$%g' "$start" "${end:-$start}")"
			else
				error "invalid input" 2
				return
			fi
		done
	done
	# The BSD seq's output will have a trailing comma which we need to remove.
	command awk $opts '{print '"${columns%,}"'}'
}

# Intelligently columnate lists.
#
# Usage:
#       col [<separator>]
#
# shellcheck disable=SC2086
col() {
	local arg="$1"
	[[ -n "$arg" ]] && arg="-s $arg"
	command column -t $arg
}

# Print stats about the numbers read from STDIN. Run `datamash --help` to see
# various grouping operations available (perc:10, pstdev, etc.)
#
# Usage:
#       dm [<grouping_operation>]...
#
# Dependencies:
#       dnf install datamash
#
# shellcheck disable=SC2046,SC2048
dm() {
	local op
	datamash --sort --header-out --round 2 mean 1 median 1 perc:90 1 perc:99 1 \
		$(for op in $*; do echo "$op 1"; done | paste -sd' ') |
		command sed 's/(field-1)//g' |
		command column -t
}

# Which RPM contains the keyword in its name.
#
# Usage:
#       dns <keyword>
dns() {
	local pkg="$1"
	if [[ $# -eq 0 ]]; then
		error "please pass the keyword" 2
		return
	elif [[ $# -gt 1 ]]; then
		error "invalid input, do not pass more than one keyword" 2
		return
	fi
	sudo dnf search -qC "$pkg" |
		command grep -i "$pkg.* :" | command grep --color=always -i "$pkg"
}

# Which RPM provides the file. It assumes that the provided filename is
# either a library or a binary.
#
# Usage:
#       dnp (<binary>|<library>)
dnp() {
	local file="$1"
	local file_type
	if [[ $# -eq 0 ]]; then
		error "please pass the filename" 2
		return
	elif [[ $# -gt 1 ]]; then
		error "invalid input, do not pass more than one filename" 2
		return
	fi
	if [[ "$file" =~ .*\.(a|la|so([0-9\.])+?)$ ]]; then
		file_type="lib"
	else
		file_type="bin"
	fi
	sudo dnf provides -qC "*/$file_type*/$file" |
		command grep -E --color=always "/.*$file_type.*/$file|"
}

# Download files.
#
# If no file is specified, then we attempt to detect the link from the clipboard.
# It notifies once the download is complete using an iTerm-specific escape
# sequence (https://iterm2.com/documentation-escape-codes.html).
#
# Usage:
#       download [<file>...]
#
# Environment variables:
#       export DOWNLOAD_ARIA_OPTIONS='(
#           ["*uri_regex1*"]="--http-user=user --http-passwd=pass"
#           ["*uri_regex2*"]="--header=\"Referer: https://example.com\""
#       )'
#
# Dependencies:
#       dnf install aria2
#
# shellcheck disable=SC1003,SC2086
download() {
	local file files file_count failed message
	local opts="--connect-timeout=2 --follow-torrent=false -x8 --continue=true"
	files="$*"
	[[ -z "$files" ]] && files="$(pbpaste)"
	[[ -z "$files" ]] && return 1
	file_count=$(command wc -w <<<"$files" | command tr -d ' ')
	failed=0
	declare -A download_opts=$DOWNLOAD_ARIA_OPTIONS
	for file in $files; do
		extra_opts=""
		for uri_regex in "${!download_opts[@]}"; do
			[[ $file =~ $uri_regex ]] &&
				extra_opts+=" ${download_opts[$uri_regex]}" && break
		done
		command aria2c $opts$extra_opts "$file" || ((failed += 1))
	done
	[[ $failed -eq 0 ]] &&
		message="download: success" ||
		message="download: $failed/$file_count failed"
	notify "$message"
	return $failed
}

# Extract the contents of an archive.
#
# Usage:
#       extract <file>
#
# Dependencies:
#       dnf install binutils cabextract p7zip p7zip-plugins unrar xz
extract() {
	if [[ -f "$1" ]]; then
		case "$1" in
		*.7z) 7z x "$1" ;;
		*.tar.bz2) tar xjf "$1" ;;
		*.bz2) bunzip2 "$1" ;;
		*.deb) ar x "$1" ;;
		*.exe) cabextract "$1" ;;
		*.tar.gz) tar xzf "$1" ;;
		*.gz) gunzip "$1" ;;
		*.jar) 7z x "$1" ;;
		*.iso) 7z x "$1" -o"${1%.*}" ;;
		*.lzma) unlzma "$1" ;;
		*.r0 | *.r00) unrar x "$1" ;;
		*.rar) unrar x "$1" ;;
		*.rpm) tar xzf "$1" ;;
		*.tar) tar xf "$1" ;;
		*.tbz2) tar xjf "$1" ;;
		*.tgz) tar xzf "$1" ;;
		*.tar.xz) tar xJf "$1" ;;
		*.xz) unxz "$1" ;;
		*.zip) 7z x "$1" ;;
		*.Z) uncompress "$1" ;;
		*)
			error "'$1' cannot be extracted" 2
			return
			;;
		esac
	else
		error "'$1' is not a file" 2
		return
	fi
}

# Find file by name.
#
# Usage:
#       ff <pattern>
ff() {
	command find -L . -type f -iname '*'"$*"'*' -ls 2>/dev/null
}

# Search the command line history and show the matches.
#
# Usage:
#       his <pattern>
his() {
	command grep "$*" "$HISTFILE" | command less +G
}

# List all network interfaces and their IPs.
#
# Usage:
#       ipp
ipp() {
	local result
	# Always prefer `ip` over `ifconfig` since the latter has been deprecated.
	if hash "ip" 2>/dev/null; then
		result="$(
			command ip -brief addr show scope global |
				command sort |
				command awk '$2 != "DOWN" {$2=""; print $0}' |
				command sed -E 's/([0-9a-f:]+)\/[0-9]+/\1/g'

		)"
	else
		result="$(
			command ifconfig |
				command grep -E '(flags=|inet)' |
				command grep -vE ' (127|169.254|::1|fe80::)' |
				command grep 'inet' -B1 |
				command grep -v '^--$' |
				command sed -E 's/(.*): flags=.*/\1/g;s/[[:space:]]+inet6?\ ([^[:space:]]*).*/+\1/g' |
				command perl -p0e 's/\n\+/ /g'
		)"
	fi
	echo -e "$result" | command column -t
}

# Intelligently parse the JSON.
#
# Usage:
#       j <file.json>
#       cat <file.json> | j
j() {
	local cmd="command jq '.'"
	[[ -t 0 ]] && cmd+=" \"$*\""
	[[ -t 1 ]] && cmd+=" -C | command less -Ri"
	eval "$cmd"
}

# Like mv, but with a progress bar.
#
# Usage:
#       msync <src> <dst>
msync() {
	rsync --remove-source-files "$@" &&
		[[ -d "$1" ]] && command find "$1" -type d -empty -delete
}

# Send a notification via the terminal.
#
# It works using OSC 9, an Xterm-specific escape sequence used to send terminal
# notifications (https://iterm2.com/documentation-escape-codes.html).
#
# Usage:
#       notify <message>
#
# shellcheck disable=SC1003
notify() {
	local output
	output="$(printf '\e]9;%s\a' "${*:-'Attention'}")"
	[[ -n "$TMUX" ]] && output="$(printf '\ePtmux;\e%s\e\\' "$output")"
	printf "%s" "$output"
}

# Copy data from STDIN to the clipboard. It removes trailing newlines.
#
# Both iTerm and Tmux are supported. For the former, you'll have to enable "Preferences >
# General > Selection > Applications in terminal may access clipboard". It works using
# OSC 52, an Xterm-specific escape sequence used to copy printed text into the clipboard.
#
# Usage:
#       echo "text message" | pbcopy
#
# shellcheck disable=SC1003
pbcopy() {
	local content output
	content="$(</dev/stdin)"
	if [[ "$OSTYPE" == "darwin"* ]]; then
		echo -n "$content" | command pbcopy
		return
	fi
	output="$(printf '\e]52;c;%s\a' "$(echo -n "$content" | command base64 -w0)")"
	[[ -n "$TMUX" ]] && output="$(printf '\ePtmux;\e%s\e\\' "$output")"
	printf "%s" "$output"
}

# Show the public IP.
#
# Usage:
#       pipp
#
# shellcheck disable=SC2086
pipp() {
	local DIG_OPTS="+short +timeout=1 +retry=1 TXT o-o.myaddr.l.google.com @ns1.google.com"
	{
		command dig -4 $DIG_OPTS
		command dig -6 $DIG_OPTS
	} |
		command sed 's/"//g;/^;;/d;/^$/d'
}

# Convert numbers to percentage.
#
# Usage:
#		cat <numbers.txt> | pct
pct() {
	command awk '{ total += $1; numbers[NR] = $1 } END { for (i = 1; i <= NR; i++) printf "%d %.2f%%\n", numbers[i], (numbers[i] / total) * 100 }' |
		command column -t
}

# Combine the lines from STDIN with an optional delimiter.
#
# Usage:
#       pst [<delimiter>]
pst() {
	command sed ':a;N;$!ba;s/\n/'"$*"'/g'
}

# Simplifed version of xargs.
xarg() {
	command xargs -P"$1" -I{} sh -c "${*:2}"
}
