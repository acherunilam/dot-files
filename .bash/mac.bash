# shellcheck disable=SC2155


# Load GNU binaries instead of the BSD variants.
export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/findutils/libexec/gnuman:$MANPATH"
export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/gnu-sed/libexec/gnuman:$MANPATH"
export PATH="/usr/local/opt/util-linux/bin:$PATH"
export PATH="/usr/local/share/john/:$PATH"
export HOMEBREW_NO_ANALYTICS=1


# Dependencies:
#       brew install brightness coreutils terminal-notifier
alias dark='brightness 0 2>/dev/null'                                       # set display brightness to 0
alias gls='gls --color=auto'                                                # export color scheme for GNU ls
alias head='ghead'                                                          # `head -n0` should work
alias lck='pmset displaysleepnow'                                           # switch off display
alias notify='terminal-notifier -sound Ping -message'                       # send notification and make a sound
alias paste='gpaste'                                                        # `paste -sd' '` should work
alias shred='gshred -vfzu -n 10'                                            # securely erase the file
alias slp='pmset sleepnow'                                                  # go to sleep


# cd into the directory that is currently open in Finder.
cdf() {
    local target
    target=$(
        osascript -e "tell application \"Finder\" to if (count of Finder \
            windows) > 0 then get POSIX path of (target of front Finder \
            window as text)" 2>/dev/null
    )
    if [[ -n $target ]] ; then
        cd "$target" || exit 1
    else
        echo "cdf: no Finder window found" >&2
        return 2
    fi
}


# Clears all recent files accessed through the GUI and CLI.
#
# Environment variables:
#       echo "export CLEAR_HISTORY_BASH_KEYWORDS='<keyword1:keyword2>'" >>~/.bash/private.bash
#       echo "export CLEAR_HISTORY_FASD_PATH='<path1:path2>'" >>~/.bash/private.bash
clear-history() {
    # Clear recent files.
    osascript -e "tell application \"System Events\" to click menu item \"Clear Menu\" of menu \
        of menu item \"Recent Items\" of menu of menu bar item \"Apple\" of menu bar of process \
        \"Finder\"" 1>/dev/null || echo "clear-history: unable to clear recent files" >&2
    # Clear recent folders.
    osascript -e "tell application \"System Events\" to click menu item \
        \"Clear Menu\" of menu of menu item \"Recent Folders\" of menu of \
        menu bar item \"Go\" of menu bar of process \"Finder\"" \
        1>/dev/null || echo "clear-history: unable to clear recent folders" >&2
    # Clear 'Go to' Folder.
    defaults delete com.apple.finder GoToField &>/dev/null
    defaults delete com.apple.finder GoToFieldHistory &>/dev/null
    killall Finder || echo "clear-history: unable to clear Go to Folder" >&2
    # Clear VLC's recent files.
    osascript -e "tell application \"VLC\" to activate" 1>/dev/null && \
        osascript -e "tell application \"Finder\" to set visible of process \"VLC\" to \
            false" 1>/dev/null && \
        osascript -e "tell application \"System Events\" to click menu item \"Clear Menu\" \
            of menu of menu item \"Open Recent\" of menu of menu bar item \"File\" of menu \
            bar 1 of process \"VLC\"" 1>/dev/null && \
        killall VLC || echo "clear-history: unable to clear recent VLC files" >&2
    # Clear Bash history lines containing any of the specified keywords.
    if [[ -n "$CLEAR_HISTORY_BASH_KEYWORDS" ]] ; then
        local hist_file="${HISTFILE:-$HOME/.bash_history}"
        local tmp_file="$(mktemp)"
        echo -e "${CLEAR_HISTORY_BASH_KEYWORDS//:/\\n}" | while read -r k ; do
            command tail -r "$hist_file" | command sed "/${k//\//\\/}/,+1d" | command tail -r \
                >"$tmp_file" && command cp -f "$tmp_file" "$hist_file"
        done || echo "clear-history: unable to clear Bash history keywords" >&2
    fi
    # Clear Fasd paths containing any of the specified paths.
    if [[ -n "$CLEAR_HISTORY_FASD_PATH" ]] ; then
        echo -e "${CLEAR_HISTORY_FASD_PATH//:/\\n}" | while read -r p ; do
            sed -i "/${p//\//\\/}/d" "${_FASD_DATA:-$HOME/.fasd}"
        done || echo "clear-history: unable to clear Fasd paths" >&2
    fi
}


# Unmount all DMGs or external HDDs.
#
# Usage:
#     unmount               Unmount the DMGs
#     unmount -e            Unmount the HDDs
eject() {
    local volume volumes disk_type label device devices
    volumes=$(diskutil list | grep "/dev/disk")
    [[ "$1" == "-e" ]] && disk_type='external' || disk_type='image'
    while read -r volume ; do
        if command grep -q $disk_type <<< "$volume" ; then
            label=$(awk '{print $1}' <<< "$volume")
            devices+=" $label"
        fi
    done <<< "$volumes"
    for device in $devices ; do
        command diskutil eject "$device"
    done
}


# Remove extended attributes for a file downloaded from the internet.
whitelist() {
    sudo command xattr -rd com.apple.metadata:kMDItemWhereFroms "$@"
    sudo command xattr -rd com.apple.quarantine "$@"
}
