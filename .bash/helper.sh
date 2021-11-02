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
alias ga='git add -A' && __git_complete ga _git_add 2>/dev/null
alias gd='git diff' && __git_complete gd _git_diff 2>/dev/null
alias gl='git lg' && __git_complete gl _git_log 2>/dev/null
alias gs='git status' && __git_complete gs _git_status 2>/dev/null
alias l='ls -CF'                                                               # distinguish between file types by suffixing file name with a symbol
alias la='ls -A'                                                               # list all files
alias ld='ls -d */ 2>/dev/null'                                                # list only directories
alias lh='ls -d .??* 2>/dev/null'                                              # list only hidden files
alias ll='ls -alFh'                                                            # list all files with their details
alias x='extract'                                                              # extract the contents of an archive
# Run with elevated privileges.
alias mtr='sudo mtr'
alias pls='sudo $(history -p \!\!)'                                            # re-execute last command with elevated privileges
alias sudo='sudo '                                                             # required to enable auto-completion if alias is prefixed with sudo
alias service='sudo service'
# Inspect the system.
if [[ "$OSTYPE" == "linux"* ]] ; then
    alias osv='cat /etc/system-release'                                        # print the Linux distribution
    alias port='sudo ss -tulpn'                                                # show all listening ports
elif [[ "$OSTYPE" == "darwin"* ]] ; then
    alias osv='sw_vers'                                                        # output Mac system version
    alias port='sudo lsof -nP -iudp -itcp -stcp:listen | grep -v ":\*"'        # show all ports listening for connections
fi
# Run with specific settings.
alias mkdir='mkdir -p'                                                         # create parent directory if it doesn't exist
alias rsync='rsync -avzhPLK --partial-dir=.rsync-partial'                      # enable compression and partial synchronization
alias xargs='xargs -rd\\n '                                                    # set default delimiter to newline instead of whitespace
# Colorize output.
if [[ "$OSTYPE" == "linux"* ]] ; then
    alias ls='ls --color=auto'
fi
alias grep='grep --color=auto '
alias watch='watch --color '


# Simplified awk.
#
# Usage:
#       aw 1-3              Prints the first 3 columns
#       aw 1-3,7            Prints the first 3 columns, followed by the 7th
#       aw 1-3,7 -F":"      Same as above, but passes the -F":" option to awk
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2086
aw() {
    local ranges start end arg
    local columns=""
    local opts=""
    for arg in "$@" ; do
        [[ "${arg::1}" != [0-9] ]] && opts+=" $arg" && continue
        IFS=',' read -ra ranges <<< "$arg"
        for range in "${ranges[@]}" ; do
            IFS='-' read -r start end <<< "$range"
            if [[ $start =~ ^[0-9]+$ ]] && [[ $end =~ ^[0-9]*$ ]] ; then
                columns+="$(command seq -s ',' -f '$%g' "$start" "${end:-$start}")"
            else
                error "invalid input" 2 ; return
            fi
        done
    done
    # The BSD seq's output will have a trailing comma which we need to remove.
    command awk $opts '{print '"${columns%,}"'}'
}


# Downloads files. If no file is specified, then we attempt to detect the link from
# the clipboard. It notifies once the download is complete using an iTerm-specific
# escape sequence (https://iterm2.com/documentation-escape-codes.html).
#
# Dependencies:
#       dnf install aria2
#       notify()
#
# Environment variables:
#       export DOWNLOAD_ARIA_OPTIONS='(
#           ["*uri_regex1*"]="--http-user=user --http-passwd=pass"
#           ["*uri_regex2*"]="--header=\"Referer: https://example.com\""
#       )'
#
# Usage:
#       download [<file>...]
#
# shellcheck disable=SC1003,SC2086
download() {
    local file files file_count failed message
    local opts="--connect-timeout=2 --follow-torrent=false -x8 --continue=true"
    files="$*"
    [[ -z "$files" ]] && files="$(pbpaste)"
    [[ -z "$files" ]] && return 1
    file_count=$(command wc -w <<< "$files" | command tr -d ' ')
    failed=0
    declare -A download_opts=$DOWNLOAD_ARIA_OPTIONS
    for file in $files ; do
        extra_opts=""
        for uri_regex in "${!download_opts[@]}" ; do
            [[ $file =~ $uri_regex ]] && extra_opts+=" ${download_opts[$uri_regex]}" && break
        done
        command aria2c $opts$extra_opts "$file" || ((failed+=1))
    done
    [[ $failed -eq 0 ]] && message="download: success" || message="download: $failed/$file_count failed"
    notify "$message"
    return $failed
}


# Extract the contents of an archive.
#
# Dependencies:
#       dnf install binutils cabextract p7zip p7zip-plugins unrar xz
#       error()
extract() {
    if [[ -f "$1" ]] ; then
        case "$1" in
            *.7z)       7z x "$1"               ;;
            *.tar.bz2)  tar xjf "$1"            ;;
            *.bz2)      bunzip2 "$1"            ;;
            *.deb)      ar x "$1"               ;;
            *.exe)      cabextract "$1"         ;;
            *.tar.gz)   tar xzf "$1"            ;;
            *.gz)       gunzip "$1"             ;;
            *.jar)      7z x "$1"               ;;
            *.iso)      7z x "$1" -o"${1%.*}"   ;;
            *.lzma)     unlzma "$1"             ;;
            *.r0|*.r00) unrar x "$1"            ;;
            *.rar)      unrar x "$1"            ;;
            *.rpm)      tar xzf "$1"            ;;
            *.tar)      tar xf "$1"             ;;
            *.tbz2)     tar xjf "$1"            ;;
            *.tgz)      tar xzf "$1"            ;;
            *.tar.xz)   tar xJf "$1"            ;;
            *.xz)       unxz "$1"               ;;
            *.zip)      7z x "$1"               ;;
            *.Z)        uncompress "$1"         ;;
            *)
                error "'$1' cannot be extracted" 2 ; return
                                                ;;
        esac
    else
        error "'$1' is not a file" 2 ; return
    fi
}


# Find file by name.
ff() {
    command find -L . -type f -iname '*'"$*"'*' -ls 2>/dev/null
}


# Search the command line history and show the matches.
his() {
    command grep "$*" "$HISTFILE" | command less +G
}

# List all network interfaces and their IPs.
ipp() {
    local interfaces ips
    interfaces="$(command ifconfig | command awk '!/^\s+/ && !/^$/ {gsub(/:$/, "", $1); print $1}')"
    for i in $interfaces ; do
        ips="$(command ifconfig "$i" 2>/dev/null | \
            command awk '/inet/ && !/inet (127|169.254)/ && !/inet6 (::1|fe80::)/ {print "\t"$2}')"
        [[ -n "$ips" ]] && echo -e "${i}${ips}"
    done
}


# Like mv, but with a progress bar.
msync() {
    rsync --remove-source-files "$@" && [[ -d "$1" ]] && command find "$1" -type d -empty -delete
}


# Sends a notification via the terminal.
#
# Both iTerm and Tmux are supported. It works using OCS 9, an Xterm-specific escape
# sequence used send terminal notifications.
#
# shellcheck disable=SC1003
notify() {
    output="$(printf '\e]9;%s\a' "${*:-'Attention'}")"
    [[ -n "$TMUX" ]] && output="$(printf '\ePtmux;\e%s\e\\' "$output")"
    printf "%s" "$output"
}


# Upload contents to @mkaczanowski's Pastebin, an open-source Rust pastebin. If no input is
# passed, then the contents of the clipboard will be used.
#
# Environment variables:
#       export PASTEBIN_URL="<url-of-pastebin>"
#       export PASTEBIN_AUTH_BASIC="user:pass"
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2086,SC2181
pb() {
    local content curl_auth_arg response
    if [[ -z "$PASTEBIN_URL" ]] ; then
        error "please set the environment variable \$PASTEBIN_URL" ; return
    fi
    if [[ -p /dev/stdin ]] ; then
        content="$(</dev/stdin)"
    elif [[ "$OSTYPE" == "darwin"* ]] ; then
        content="$(pbpaste)"
    fi
    if [[ -z "$content" ]] ; then
        error "please pass the text to upload via STDIN" 2 ; return
    fi
    [[ -n $PASTEBIN_AUTH_BASIC ]] && curl_auth_arg="-u $PASTEBIN_AUTH_BASIC"
    response="$(
        command curl -qsS --connect-timeout 2 --max-time 5 \
            -XPOST $curl_auth_arg --data-binary @- "$PASTEBIN_URL" <<< "$content"
    )"
    if [[ $? -ne 0 ]] ; then
        error "unable to connect to $PASTEBIN_URL" ; return
    fi
    if [[ -z "$response" ]] ; then
        error "unknown error, missing output" ; return
    fi
    echo "$response"
    echo -n "$response" | pbcopy
}


# Copies data from STDIN to the clipboard. It removes trailing newlines.
#
# Both iTerm and Tmux are supported. For the former, you'll have to enable "Preferences >
# General > Selection > Applications in terminal may access clipboard". It works using
# OCS 52, an Xterm-specific escape sequence used to copy printed text into the clipboard.
#
# Usage:
#       echo "text message" | pbcopy
#
# Dependencies:
#       error()
#
# shellcheck disable=SC1003
pbcopy() {
    if [[ "$OSTYPE" == "darwin"* ]] ; then
        command pbcopy
        return
    fi
    content="$(</dev/stdin)"
    if [[ -z "$content" ]] ; then
        error "missing input, please pass the text" 2 ; return
    fi
    output="$(printf '\e]52;c;%s\a' "$(echo -n "$content" | command base64 -w0)")"
    [[ -n "$TMUX" ]] && output="$(printf '\ePtmux;\e%s\e\\' "$output")"
    printf "%s" "$output"
}


# Show the public IP.
#
# shellcheck disable=SC2086
pipp() {
    local DIG_OPTS="+short +timeout=1 +retry=1 myip.opendns.com @resolver1.opendns.com"
    command dig -4 A $DIG_OPTS
    command dig -6 AAAA $DIG_OPTS
}

# Upload contents to Sprunge, a public pastebin. If no input is passed, then the
# contents of the clipboard will be used.
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2181
ppb() {
    local content response
    local SPRUNGE_URL="http://sprunge.us"
    if [[ -p /dev/stdin ]] ; then
        content="$(</dev/stdin)"
    elif [[ "$OSTYPE" == "darwin"* ]] ; then
        content="$(pbpaste)"
    fi
    if [[ -z "$content" ]] ; then
        error "please pass the text to upload via STDIN" 2 ; return
    fi
    response="$(
        command curl -qsS --connect-timeout 2 --max-time 5 -F 'sprunge=<-' $SPRUNGE_URL <<< "$content"
    )"
    if [[ $? -ne 0 ]] ; then
        error "unable to connect to $SPRUNGE_URL" ; return
    fi
    if [[ -z "$response" ]] ; then
        error "unknown error, missing output" ; return
    fi
    echo "$response"
    echo -n "$response" | pbcopy
}


# Sends a push notification using Pushover (https://pushover.net/). The user and token can
# be obtained by registering your app over here (https://pushover.net/apps/build).
#
# Environment variables:
#       export PUSHOVER_USER="<user>"
#       export PUSHOVER_TOKEN="<token>"
#
# Usage:
#       push foo              Sends the message 'foo'
#       push -p bar           Sends the message 'bar' with high priority
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2155,SC2181,SC2199
push() {
    help() {
        echo "Usage: ${FUNCNAME[1]} [options] <message>
Sends a push notification using Pushover (https://pushover.net/). The user and token can
be obtained by registering your app over here (https://pushover.net/apps/build).

Environment variables:
  export PUSHOVER_USER=\"<user>\"
  export PUSHOVER_TOKEN=\"<token>\"

Options:
  -h    Print this help message.
  -p    Send the message with high priority."
    }

    local columns OPTIND
    local priority=0
    while getopts ":phv" arg ; do
        case $arg in
            p)  # priority
                priority=1
                ;;
            h)  # help
                help && return
                ;;
            *)
                help >&2 && return 2
                ;;
        esac
    done
    shift $((OPTIND-1))
    if [[ -z "$PUSHOVER_USER" ]] || [[ -z "$PUSHOVER_TOKEN" ]] ; then
        error "missing environment variables, please set both PUSHOVER_USER and PUSHOVER_TOKEN" ; return
    fi
    [[ "$1" == "-p" ]] && priority=1 && shift
    [[ "${@: -1}" == "-p" ]] && priority=1 && set -- "${@:1:$(($#-1))}"
    local message="$*"
    if [[ -z "$message" ]] ; then
        error "missing input, please pass a message" 2 ; return
    fi
    local response="$(
        command curl -qsS --connect-timeout 2 --max-time 5 \
            --form-string "user=$PUSHOVER_USER" \
            --form-string "token=$PUSHOVER_TOKEN" \
            --form-string "priority=$priority" \
            --form-string "message=$message" \
            "https://api.pushover.net/1/messages.json"
    )"
    if [[ $? -ne 0 ]] ; then
        error "unable to connect to pushover.net" ; return
    fi
    if command grep -q '"user":"invalid"' <<< "$response" ; then
        error "invalid user, please check the environment variable PUSHOVER_USER" ; return
    elif command grep -q '"token":"invalid"' <<< "$response" ; then
        error "invalid token, please check the environment variable PUSHOVER_TOKEN" ; return
    elif ! command grep -q '"status":1' <<< "$response" ; then
        error "unknown error: $response" ; return
    fi
}


# Shorten the given URL using Shlink, an open-source URL Shortener. The API key can be
# generated from by running `bin/cli api-key:generate`.
#
# Environment variables:
#       export URL_SHORTENER_API_KEY="<generated-api-key>"
#       export URL_SHORTENER_URL="<url-of-endpoint>"
#
# Usage:
#       url-shorten <url>             Shortens the given URL, uses a randomized 4-letter slug
#       url-shorten <url> <slug>      Shortens the given URL using the given slug. If slug
#                                       already exists, then it overwrites it
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2015,SC2181
url-shorten() {
    local custom_slug response result
    local url="$1"
    if [[ -z "$URL_SHORTENER_URL" ]] || [[ -z "$URL_SHORTENER_API_KEY" ]] ; then
        error "please set both the environment variables \$URL_SHORTENER_URL and \$URL_SHORTENER_API_KEY" ; return
    fi
    if [[ -z $url ]] ; then
        error "please pass the URL as the first argument" 2
    elif [[ ! $url =~ ^https?://[^\.]+\..+$ ]] ; then
        error "'$url' is not a valid URL" 2
    fi
    [[ -n "$2" ]] && custom_slug=", \"customSlug\": \"$2\""
    response="$(
        command curl -qsS --connect-timeout 2 --max-time 5 \
            -X POST "$URL_SHORTENER_URL/rest/v2/short-urls" \
            -H "X-Api-Key: $URL_SHORTENER_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"longUrl\": \"$url\"$custom_slug}"
    )"
    if [[ $? -ne 0 ]] ; then
        error "unable to connect to $URL_SHORTENER_URL" ; return
    fi
    if command grep -q '"type":"INVALID_SLUG"' <<< "$response" ; then
        command curl -qsS --connect-timeout 2 --max-time 5 \
            -X PATCH "$URL_SHORTENER_URL/rest/v2/short-urls/$2" \
            -H "X-Api-Key: $URL_SHORTENER_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"longUrl\": \"$url\"}" \
            && response="{\"shortUrl\": \"$URL_SHORTENER_URL/$2\"}" \
            || { error "unable to connect to $URL_SHORTENER_URL" ; return ;}
    fi
    result="$(echo "$response" | command tr ',' '\n' | command sed -En 's/.*"shortUrl":"(.*)"/\1/p')"
    if [[ -z "$result" ]] ; then
        error "unknown error, missing output" ; return
    fi
    echo "$result"
    echo -n "$result" | pbcopy
}