# shellcheck shell=bash
# shellcheck disable=SC1091,SC2139,SC2155


[[ "$OSTYPE" != "darwin"* ]] && return


export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}";
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar";
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX";
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH+:$PATH}";
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}";
include "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
for file in "$HOMEBREW_PREFIX/etc/bash_completion.d/"* ; do
    include "$file"
done

# Preview the colors here (https://geoff.greer.fm/lscolors/).
export CLICOLOR=1
export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD
export TERMINFO_DIRS="$TERMINFO_DIRS:$HOME/.local/share/terminfo"


# Load Metasploit (https://github.com/rapid7/metasploit-framework) binaries.
export PATH="/opt/metasploit-framework/bin:$PATH"


# Configure Secretive (https://github.com/maxgoedjen/secretive), a Secure Enclave-based SSH Agent.
# export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
# export PATH="$HOMEBREW_PREFIX/opt/openssh/bin:$PATH"


# Load GNU binaries instead of the BSD variants.
export PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"
export PATH="$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/opt/findutils/libexec/gnuman:$MANPATH"
export PATH="$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnubin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnuman:$MANPATH"
export PATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnuman:$MANPATH"
export PATH="$HOMEBREW_PREFIX/opt/util-linux/bin:$PATH"
alias awk='gawk'                                                            # `awk -vFPAT` should work
alias base64='gbase64'                                                      # `base64 -w0` should work
alias date='gdate'                                                          # `date -I` should work
alias head='ghead'                                                          # `head -n0` should work
alias paste='gpaste'                                                        # `paste -sd' '` should work
alias tac='gtac'                                                            # BSD doesn't have tac


# Dependencies:
#       brew install brightness coreutils mtr
alias dark='brightness 0 2>/dev/null'                                       # set display brightness to 0
alias gls='gls --color=auto'                                                # export color scheme for GNU ls
alias lck='pmset displaysleepnow'                                           # switch off display
alias osv='sw_vers'                                                         # output macOS system version
alias mtr="sudo mtr"                                                        # run with elevated privileges by default
alias port='sudo lsof -nP -iudp -itcp -stcp:listen | grep -v ":\*"'         # show all ports listening for connections
alias shred='gshred -vfzu -n 10'                                            # securely erase the file
alias slp='pmset sleepnow'                                                  # go to sleep


# Used to shutdown/reboot immediately.
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
# Dependencies:
#       error()
cdf() {
    local target="$(
        osascript -e "tell application \"Finder\" to if (count of Finder \
            windows) > 0 then get POSIX path of (target of front Finder \
            window as text)" 2>/dev/null
    )"
    if [[ -n $target ]] ; then
        cd "$target" || return 1
    else
        error "no Finder window found" 2 ; return
    fi
}


# Delete all small (>10M) downloaded files.
clean() {
    local cmd="command find $HOME/Downloads/ -maxdepth 1 -type f -size -10M \
        ! -name '.DS_Store' ! -name '*.crdownload' ! -name '*.aria2'"
    [[ "$1" != "-n" ]] && cmd+=" -exec rm -v {} +"
    eval "$cmd" | command sed -E "s/^${HOME//\//\\/}\/Downloads\///g"
}


# Clears all recent files accessed through the GUI and CLI.
#
# Environment variables:
#       export CLEAR_HISTORY_BASH_KEYWORDS="<keyword1:keyword2>"
#       export CLEAR_HISTORY_FASD_PATH="<path1:path2>"
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2015
clear-history() {
    # Clear recent files.
    osascript -e "tell application \"System Events\" to click menu item \"Clear Menu\" of menu \
        of menu item \"Recent Items\" of menu of menu bar item \"Apple\" of menu bar of process \
        \"Finder\"" 1>/dev/null || error "unable to clear recent files"
    # Clear recent folders.
    osascript -e "tell application \"System Events\" to click menu item \
        \"Clear Menu\" of menu of menu item \"Recent Folders\" of menu of \
        menu bar item \"Go\" of menu bar of process \"Finder\"" \
        1>/dev/null || error "unable to clear recent folders"
    # Clear 'Go to' Folder.
    defaults delete com.apple.finder GoToField &>/dev/null
    defaults delete com.apple.finder GoToFieldHistory &>/dev/null
    killall Finder || error "unable to clear Go to Folder"
    # Clear VLC's recent files.
    osascript -e "tell application \"VLC\" to activate" 1>/dev/null \
        && osascript -e "tell application \"Finder\" to set visible of process \"VLC\" to \
            false" 1>/dev/null \
        && osascript -e "tell application \"System Events\" to click menu item \"Clear Menu\" \
            of menu of menu item \"Open Recent\" of menu of menu bar item \"File\" of menu bar \
            1 of process \"VLC\"" 1>/dev/null \
        && killall VLC || error "unable to clear recent VLC files"
    # Clear Bash history lines containing any of the specified keywords.
    if [[ -n "$CLEAR_HISTORY_BASH_KEYWORDS" ]] ; then
        local hist_file="${HISTFILE:-$HOME/.bash_history}"
        local tmp_file="$(mktemp)"
        echo -e "${CLEAR_HISTORY_BASH_KEYWORDS//:/\\n}" | while read -r k ; do
            command tail -r "$hist_file" | command sed "/${k//\//\\/}/,+1d" | command tail -r \
                >"$tmp_file" && command cp -f "$tmp_file" "$hist_file"
        done || error "unable to clear Bash history keywords"
    fi
    # Clear Fasd paths containing any of the specified paths.
    if [[ -n "$CLEAR_HISTORY_FASD_PATH" ]] ; then
        echo -e "${CLEAR_HISTORY_FASD_PATH//:/\\n}" | while read -r p ; do
            command sed -i "/${p//\//\\/}/d" "${_FASD_DATA:-$HOME/.fasd}"
        done || error "unable to clear Fasd paths"
    fi
}


# Unmount all DMGs or external HDDs.
#
# Usage:
#       unmount [-e]
#
# Options:
#       -e      Unmount HDDs instead of DMGs.
eject() {
    local volume volumes disk_type label device devices
    volumes=$(command diskutil list | command grep "/dev/disk")
    [[ "$1" == "-e" ]] && disk_type='external' || disk_type='image'
    while read -r volume ; do
        if command grep -q $disk_type <<< "$volume" ; then
            label=$(command awk '{print $1}' <<< "$volume")
            devices+=" $label"
        fi
    done <<< "$volumes"
    for device in $devices ; do
        command diskutil eject "$device"
    done
}


# Set iTerm's tab title.
#
# It works using OSC 9, an Xterm-specific escape sequence used to send terminal notifications.
# (https://iterm2.com/documentation-escape-codes.html).
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


# Move the downloaded files matching the given regex into current directory.
#
# Usage:
#       mdownload [<pattern>]
mdownload() {
    local cmd is_dry_run
    [[ "$1" == "-n" ]] && shift && is_dry_run=1
    cmd="command find $HOME/Downloads/ -maxdepth 1 -type f -iname '*'$*'*' \
        ! -name '.DS_Store' ! -name '*.crdownload' ! -name '*.aria2'"
    [[ -z "$is_dry_run" ]] && cmd+=' -exec mv -v {} . \;'
    eval "$cmd"
}


# Generate OTP using the TOTP secret stored in Keychain. You can add it to the Keychain
# by using the pass() helper method.
#
# Usage:
#       otp <key>
#
# Dependencies:
#       brew install oath-toolkit
#       error()
#       pass()
#       validate-env()
#
# Environment variables:
#       export OTP_KEYS=("facebook" "google" "twitter")
otp() {
    local key="$1"
    validate-env "OTP_KEYS" || return
    if ! [[ "$key" =~ ^($(command sed 's/\ /|/g' <<< "${OTP_KEYS[@]}"))$ ]] ; then
        error "key has to be one of: ${OTP_KEYS[*]}" 2 ; return
    fi
    local secret="$(
        command security find-generic-password -a "$LOGNAME" -s "$key" -w 2>/dev/null
    )"
    if [[ -z "$secret" ]] ; then
        error "'$key' is missing from the Keychain" ; return
    fi
    result=$(command oathtool --totp -b "$secret")
    echo "$result"
    echo -n "$result" | pbcopy
}


# Create/read/update/delete key-value pairs in the macOS Keychain.
#
# Usage:
#       pass get <key>
#       pass set <key> <value>
#       pass del <key>
#
# Dependencies:
#       error()
pass() {
    help() {
        echo "Usage: ${FUNCNAME[1]} get <key>
       ${FUNCNAME[1]} set <key> <value>
       ${FUNCNAME[1]} del <key>
       ${FUNCNAME[1]} help

Create/read/update/delete key-value pairs in the macOS Keychain."
    }

    local op="$1"
    local key="$2"
    if [[ "$op" =~ ^(get|set|del)$ ]] && [[ -z "$key" ]] ; then
        error "please specify the key" 2 ; return
    fi
    local cmd='command security'
    local cmd_opts="-a \"$LOGNAME\" -s \"$key\""
    case $op in
        get)
            eval "$cmd find-generic-password $cmd_opts -w 2>/dev/null"
            ;;
        set)
            if [[ -z "${3+foo}" ]] ; then
                error "please specify the value" 2 ; return
            fi
            eval "$cmd add-generic-password $cmd_opts -Uw $3"
            ;;
        del)
            eval "$cmd delete-generic-password $cmd_opts &>/dev/null"
            ;;
        help)
            help && return
            ;;
        *)
            help >&2 && return 2
            ;;
    esac
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
    command osascript -e "set the clipboard to { \
        string:\"$plaintext\", \
        «class HTML»:«data HTML${htmlbinary}» \
    }"
}


# Paste the image on your clipboard to the current directory.
#
# Usage:
#       pngpaste [<filename>]
pngpaste() {
    local filename="${1:-screenshot.png}"
    [[ $filename == *.png ]] || filename+=".png"
    osascript -e "
        tell application \"System Events\" to write (the clipboard as «class PNGf») \
        to (make new file at folder \"$PWD\" with properties {name:\"$filename\"})
    " 2>/dev/null
}


# Remove extended attributes for a file downloaded from the internet.
whitelist() {
    sudo command xattr -rd com.apple.metadata:kMDItemWhereFroms "$@"
    sudo command xattr -rd com.apple.quarantine "$@"
}
