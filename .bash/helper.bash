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
    alias osv='cat /etc/os-release'                                            # output Linux distribution
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


# Downloads files. If no file is specified, then we attempt to detect the link from
# the clipboard.
#
# Dependencies:
#       dnf install aria2
#
# Environment variables:
#       export DOWNLOAD_ARIA_OPTIONS='(
#           ["*uri_regex1*"]="--http-user=user --http-passwd=pass"
#           ["*uri_regex2*"]="--header=\"Referer: https://example.com\""
#       )'
#
# Usage:
#       download [<file>...]
# shellcheck disable=SC1003,SC2086
download() {
    local file files file_count failed message
    local opts="--follow-torrent=false -x8 --continue=true"
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
    printf '\033]9;%s\033\\' "$message"
    return $failed
}


# Extract the contents of an archive.
#
# Dependencies:
#       dnf install binutils cabextract p7zip p7zip-plugins unrar xz
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
            *.lzma)     unlzma "$!"             ;;
            *.r0)       unrar x "$1"            ;;
            *.r00)      unrar x "$1"            ;;
            *.r000)     unrar x "$1"            ;;
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
                echo "extract: '$1' cannot be extracted" >&2
                return 2                          ;;
        esac
    else
        echo "extract: '$1' is not a file" >&2
        return 2
    fi
}


# Find file by name.
ff() {
    find -L . -type f -iname '*'"$*"'*' -ls 2>/dev/null
}


# Search the command line history and show the matches.
his() {
    grep "$*" "$HISTFILE" | less +G
}

# List all network interfaces and their IPs.
ipp() {
    local interfaces ips
    interfaces="$(command ifconfig | command awk '!/^\s+/ && !/^$/ {gsub(/:$/, "", $1); print $1}')"
    for i in $interfaces ; do
        ips="$(ifconfig "$i" 2>/dev/null | command awk '/inet/ && !/inet (127|169.254)/ && !/inet6 (::1|fe80::)/ {print "\t"$2}')"
        [[ -n "$ips" ]] && echo -e "${i}${ips}"
    done
}


# Like mv, but with a progress bar.
msync() {
    rsync --remove-source-files "$@"
    local exit_code=$?
    if [[ $exit_code -eq 0 ]] && [[ -d "$1" ]] ; then
        command find "$1" -type d -empty -delete
    fi
    return $exit_code
}


# Upload contents to Haste, an open-source Node.js pastebin. If no input is passed,
# then the contents of the clipboard will be used.
#
# Environment variables:
#       export PASTEBIN_URL="<url-of-pastebin>"
#       export PASTEBIN_AUTH_BASIC="user:pass"
# shellcheck disable=SC2086
pb() {
    local pb_url content response short_url
    local curl_auth_arg=""
    pb_url="${PASTEBIN_URL:-https://hastebin.com/}"
    if [[ -p /dev/stdin ]] ; then
        content="$(cat)"
    elif [[ "$OSTYPE" == "darwin"* ]] ; then
        content="$(pbpaste)"
    else
        return 2
    fi
    [[ -n $PASTEBIN_AUTH_BASIC ]] && curl_auth_arg="-u $PASTEBIN_AUTH_BASIC"
    response="$(echo "$content" | curl -sS -XPOST $curl_auth_arg --data-binary @- "$pb_url/documents")"
    short_url="$pb_url/$(echo "$response" | cut -d'"' -f4)"
    echo "$short_url"
    echo -n "$short_url" | pbcopy
}


# Copies data from STDIN to the clipboard. For Linux, both iTerm and Tmux are
# supported. For the former, you'll have to enable "Preferences > General >
# Selection > Applications in terminal may access clipboard".
#
# Usage:
#       echo "text message" | pbcopy
# shellcheck disable=SC1003
pbcopy() {
    if [[ "$OSTYPE" == "darwin"* ]] ; then
        command pbcopy
        return $?
    fi
    content="$(</dev/stdin)"
    if [[ -z "$content" ]] ; then
        echo "pbcopy: missing input, please pass the text" >&2
        return 2
    fi
    output="$(printf '\033]52;c;%s\a' "$(command base64 -w0 <<< "$content")")"
    [[ -n "$TMUX" ]] && output="$(printf '\033Ptmux;\033%s\033\\' "$output")"
    printf "%s" "$output"
}


# Show the public IP.
# shellcheck disable=SC2086
pipp() {
    local DIG_OPTS="+short +timeout=1 +retry=1 myip.opendns.com @resolver1.opendns.com"
    command dig -4 A $DIG_OPTS
    command dig -6 AAAA $DIG_OPTS
}

# Upload contents to Sprunge, a public pastebin. If no input is passed, then the
# contents of the clipboard will be used.
ppb() {
    local content short_url
    if [[ -p /dev/stdin ]] ; then
        content="$(cat)"
    elif [[ "$OSTYPE" == "darwin"* ]] ; then
        content="$(pbpaste)"
    else
        return 2
    fi
    short_url="$(echo "$content" | curl -sS -F 'sprunge=<-' http://sprunge.us)"
    echo "$short_url"
    echo -n "$short_url" | pbcopy
}


# Send push notifications to your mobile device via the service Pushover.
# The token can be fetched from over here (https://pushover.net/apps/build).
#
# Environment variables:
#       export PUSHOVER_USER="<user>"
#       export PUSHOVER_TOKEN="<token>"
# 
# Usage:
#     push foo              Sends the message 'foo'
#     push -h bar           Sends the message 'bar' with high priority
push() {
    local priority=0
    [[ "$1" == "-h" ]] || [[ "$1" == "--high" ]] && priority=1 && shift
    local message="$*"
    if [[ -z "$message" ]] ; then
        echo "push: please pass a message" >&2
        return 2
    fi
    curl -sS --form-string "user=$PUSHOVER_USER" \
        --form-string "token=$PUSHOVER_TOKEN" \
        --form-string "priority=$priority" \
        --form-string "message=$message" \
        "https://api.pushover.net/1/messages.json" 1>/dev/null
}


# Shorten the given URL using Shlink, an open-source URL Shortener. The API key can be
# generated from by running `bin/cli api-key:generate`.
# 
# Dependencies:
#       dnf install jq
#
# Environment variables:
#       export URL_SHORTENER_ENDPOINT="<url-of-endpoint>"
#       export URL_SHORTENER_API_KEY="<generated-api-key>"
# 
# Usage:
#     url-shorten <url>             Shortens the given URL, uses a randomized 4-letter slug
#     url-shorten <url> <slug>      Shortens the given URL using the given slug. If slug
#                                       already exists, then it overwrites it
url-shorten() {
    local url result short_url custom_slug
    local url="$1"
    if [[ -z $url ]] ; then
        echo "Please pass the URL as the first argument" >&2
        return 2
    elif [[ ! $url =~ ^https?://[^\ ]+$ ]] ; then
        echo "'$url' is not a valid URL" >&2
        return 2
    fi
    [[ -n "$2" ]] && custom_slug=", \"customSlug\": \"$2\""
    result="$(
        curl -sS -X POST "$URL_SHORTENER_ENDPOINT/rest/v2/short-urls" \
            -H "X-Api-Key: $URL_SHORTENER_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"longUrl\": \"$url\"$custom_slug}"
    )"
    if [[ "$(jq '.type' <<< "$result")" == "\"INVALID_SLUG\"" ]] ; then
       curl -sS -X PATCH "$URL_SHORTENER_ENDPOINT/rest/v2/short-urls/$2" \
            -H "X-Api-Key: $URL_SHORTENER_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"longUrl\": \"$url\"}" && \
            result="{\"shortUrl\": \"$URL_SHORTENER_ENDPOINT/$2\"}"
    fi
    short_url="$(jq '.shortUrl' <<< "$result" | sed -E 's/"//g')"
    echo "$short_url"
    echo -n "$short_url" | pbcopy
}
