# shellcheck shell=bash


# Load ACME client settings (https://github.com/acmesh-official/acme.sh).
#
# Dependencies:
#       curl https://get.acme.sh | sh -s email=my@example.com
include "$HOME/.acme.sh/acme.sh.env"


# Load BCC tools (https://github.com/iovisor/bcc/).
#
# Dependencies:
#       dnf install bcc-tools
export PATH="/usr/share/bcc/tools:$PATH"


# Geolocates the IP.
#
# Dependencies:
#       dnf install GeoIP GeoIP-GeoLite-data-extra
alias geo='geoiplookup'


# Prints the AS details for the given IP or ASN.
#
# Usage:
#       asn 8.8.8.8
#       asn 2a03:2880:f10c::
#       asn 32934
#       asn AS15169
#       asn ASN55836
#
# Dependencies:
#       dnf install coreutils
#       error()
#
# shellcheck disable=SC2155
asn() {
    local V4_CYMRU_NS="origin.asn.cymru.com"
    local V6_CYMRU_NS="origin6.asn.cymru.com"
    local AS_CYMRU_NS="asn.cymru.com"

    query_cymru() {
        command dig +short TXT "$1" | command sed -E 's/"//g'
    }

    append_asn_and_print() {
        local asn asn_info ip_info
        ip_info="$(query_cymru "$1.$2" | command sort | command head -n1)"
        [[ -z "$ip_info" ]] && return 1
        asn=$(command awk '{print $1}' <<< "$ip_info")
        asn_info="$(query_cymru "AS$asn.$AS_CYMRU_NS" | command awk -F'|' '{print $5}')"
        echo "$ip_info |$asn_info"
    }

    local prefix output hextets exploded_ip
    local input="$(echo "${1,,}" | command sed -E 's/\/[0-9]+$//g')"
    # IPv4
    if [[ $input =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
        prefix="$(echo "$input" | command tr '.' '\n' | tac | paste -sd'.')"
        append_asn_and_print "$prefix" "$V4_CYMRU_NS"
    # IPv6
    elif [[ $input =~ :[0-9a-f:]+ ]] ; then
        hextets=$(echo "$input" | command sed 's/::/:/g;s/:/\n/g;/^$/d' | command wc -l)
        exploded_ip="$(
            echo "$input" | command sed -E "s/::/:$(command yes "0:" | command head -n $((8 - hextets)) | paste -sd '')/g;s/^://g;s/:$//g"
        )"
        prefix="$(
            echo "$exploded_ip" | command tr ':' '\n' | while read -r line ; do printf "%04x\n" "0x$line" 2>/dev/null ; done \
                | tac | command rev | command sed -E 's/./&\./g' | paste -sd '' | command sed -E 's/\.$//g'
        )"
        append_asn_and_print "$prefix" "$V6_CYMRU_NS"
    # ASN
    elif [[ $input =~ ^(asn?)?[0-9]+$ ]] ; then
        prefix="$(echo "$input" | command sed -E 's/^asn?//g')"
        output="$(query_cymru "AS$prefix.$AS_CYMRU_NS")"
        [[ -n "$output" ]] && echo "$output"
    else
        error "invalid input, please pass an IP or ASN" 2 ; return
    fi
}


# Prints the details for the given IATA airport code.
#
# Usage:
#       iata sea        # Case insensitive search
#       iata sea -v     # Print verbose details of the airport
#       iata -i         # Install a cron job to periodically update the IATA DB
#       iata -s         # Sync the local IATA DB to the latest version
#
# Dependencies:
#       dnf install util-linux
#       error()
#
# shellcheck disable=SC2015,SC2016,SC2199
iata() {
    local CRON_SCHEDULE="0 5 * * *"  # every day 5 AM
    local DB_PATH="$HOME/.local/share/iata/airports.dat"

    download_iata_db() {
        command curl -qsS --connect-timeout 2 --max-time 5 \
            "https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat" --create-dirs -o "$DB_PATH"
    }

    help() {
        echo "Usage: ${FUNCNAME[1]} [options] <iata_code>
Prints the details for the given IATA airport code.

Options:
  -h    Print this help message.
  -i    Install a cron job to periodically update the IATA DB.
  -s    Sync the local IATA DB to the latest version.
  -v    Print verbose details of the airport."
    }

    local columns OPTIND
    local verbose=0
    while getopts ":ishv" arg ; do
        case $arg in
            i)  # install
                echo -e "$(command crontab -l)\n\n# Update IATA DB.\n$CRON_SCHEDULE bash -ic 'iata -s'" | command crontab - \
                    && error "installed cron tab" 0 \
                    || error "installation failed"
                return
                ;;
            s)  # sync
                download_iata_db && error "synced IATA DB" 0 || error "sync failed"
                return
                ;;
            h)  # help
                help && return
                ;;
            v)  # verbose
                verbose=1
                ;;
            *)
                help >&2 && return 2
                ;;
        esac
    done
    shift $((OPTIND-1))
    # Allow '-v' to be passed after the input.
    [[ "${@: -1}" == "-v" ]] && verbose=1 && set -- "${@:1:$(($#-1))}"
    if [[ $# -eq 0 ]] ; then
        error "please pass the airport code" 2 ; return
    elif [[ $# -gt 1 ]] ; then
        error "invalid input, do not pass more than one airport code" 2 ; return
    fi

    [[ ! -f "$DB_PATH" ]] && download_iata_db
    if [[ $verbose -eq 0 ]] ; then
        columns='$3", "$4'
    else
        columns="$(echo '
"ID| "$1
"Name| "$2
"City| "$3
"Country| "$4
"IATA| "$5
"ICAO| "$6
"Latitude| "$7
"Longitude| "$8
"Altitude| "$9 " ft"
"UTC offset| "$10
"DST| "$11
"Time zone| "$12
"Map| https://www.google.com/maps/search/?api=1&query="$7"%2C"$8
' | paste -sd '' | command sed -E 's/"([^\$% ])/"\\n\1/g;s/"\\n"/\\n/g')"
    fi
    # I need exit code 1 if there's no match.
    command awk -F',' '$5 == "\"'"${1^^}"'\"" { gsub(/"/, ""); print '"${columns,,}"'}' "$DB_PATH" | command column -t -s"|" -o":" | command grep .
}


# Identifies the bottleneck in the shell startup time by profiling your dot files. If the
# dot file isn't specified, it defaults to sourcing both /etc/profile and ~/.bashrc.
#
# Usage:
#       profile [<dot_file>]
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2155
profile() {
    local src_cmd
    if [[ $# -eq 0 ]] ; then
        src_cmd="source /etc/profile ; source ~/.bashrc"
    elif [[ $# -gt 1 ]] ; then
        error "do not specify more than one dot file" 2 ; return
    else
        src_cmd="source $1"
    fi
    local CONTEXT_LINES=2
    local script_file="$(command mktemp)"
    cat <<EOF >"$script_file"
OUT_FILE="\$(command mktemp)"
TMP_FILE="\$(command mktemp)"

exec 2>/dev/null
exec 3>"\$OUT_FILE"
export BASH_XTRACEFD=3
PS4='+ \$EPOCHREALTIME\011(\${BASH_SOURCE}:\${LINENO}): \${FUNCNAME[0]:+\${FUNCNAME[0]}(): }'
set -x
$src_cmd
set +x

command grep -E '\++\ 1640' "\$OUT_FILE" | command awk '{print \$2}' >"\$TMP_FILE"
timestamp="\$(command python3 -c "
a = open('\$TMP_FILE').read().split();
x = [float(a[i+1]) - float(a[i]) for i in range(len(a)-1)];
print(a[x.index(max(x))])
")"
command grep -E "\++\ \$timestamp.*" "\$OUT_FILE" -B$CONTEXT_LINES -A$CONTEXT_LINES --color=always
command command rm "\$OUT_FILE" "\$TMP_FILE"
EOF
    command bash --noprofile --norc -il "$script_file"
    command rm "$script_file"
}
