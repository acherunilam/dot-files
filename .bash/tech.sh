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
#       asn 8.8.8.8                 # Print details of the ASN owning this IP
#       asn 2a03:2880:f10c::
#       asn 32934                   # Print details of this ASN
#       asn AS15169
#       asn ASN55836
#       asn AS54115 -p              # List all prefixes for this ASN
#
# Dependencies:
#       dnf install coreutils jq netmask
#       error()
#
# shellcheck disable=SC2046,SC2155,SC2199
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

    help() {
        echo "Usage: ${FUNCNAME[1]} <ip_address>
       ${FUNCNAME[1]} [-p] <asn>
Prints the AS details of an IP or ASN.

Options:
  -p    Print all prefixes belonging to the ASN.
  -h    Print this help message."
    }

    local OPTIND prefix output hextets exploded_ip
    local all_prefixes=0
    while getopts ":ph" arg; do
        case $arg in
            p)  # prefixes
                all_prefixes=1
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
    # Allow arguments to be passed after the input.
    [[ "${@: -1}" == "-p" ]] \
        && all_prefixes=1 \
        && set -- "${@:1:$(($#-1))}"
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
        if [[ $all_prefixes -eq 1 ]] ; then
            # Use RIPE's API (https://stat.ripe.net/docs/data_api) to fetch prefixes seen by at least 10 RIS peers over the last 2 weeks.
            output="$(
                command curl -qsS --connect-timeout 1 --max-time 5 "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS$prefix" \
                    | command jq -r '.data.prefixes[].prefix' \
                    | command sort -n
            )"
            # Combine CIDRs if the `netmask` tool (https://github.com/tlby/netmask) is available.
            command -v netmask 1>/dev/null \
                && output="$(command netmask -c $(paste -sd' ' <<< "$output"))"
        else
            output="$(query_cymru "AS$prefix.$AS_CYMRU_NS")"
        fi
        [[ -n "$output" ]] && echo "$output"
    else
        error "invalid input, please pass an IP or ASN" 2 ; return
    fi
}


# Prints the details of the IATA airport code or country code.
#
# Usage:
#       iata sea            # Prints city and country of the airport
#       iata sea -v         # Prints verbose details of the airport
#       iata mumbai         # Searches for the airport by name
#       iata IN             # Prints country name for the given ISO 3166 two-letter code
#       iata germany -l     # Looks up country code by the country name
#       iata -i             # Installs a cron job to periodically update the DB
#       iata -s             # Syncs the local IATA DB to the latest version
#
# Dependencies:
#       dnf install util-linux
#       error()
#
# shellcheck disable=SC2015,SC2016,SC2199
iata() {
    local CRON_SCHEDULE="0 5 * * *"  # every day 5 AM
    local DB_PATH="$HOME/.local/share/iata"

    airport_search() {
        [[ -n "$2" ]] && opts="-i"
        command grep $opts "$1" "$DB_PATH/airports.csv" \
            | command awk -F, '{gsub("\"", ""); OFS=","; print $14, $11, $8, $9, $4, $5, $6, $17}' \
            | command grep -v '^,'
    }

    country_code_to_name() {
        command awk -F, '$2 == "\"'"$1"'\"" {gsub("\"", ""); print $3}' "$DB_PATH/countries.csv"
    }

    download_iata_db() {
        command curl -qsS --connect-timeout 2 --max-time 5 \
            "https://raw.githubusercontent.com/davidmegginson/ourairports-data/main/$1.csv" --create-dirs -o "$DB_PATH/$1.csv"
    }

    help() {
        echo "Usage: ${FUNCNAME[1]} [-v] <iata_code|country_code|city>
       ${FUNCNAME[1]} -l <country>
       ${FUNCNAME[1]} (-i | -s)
Prints the details of the IATA airport code or country code.

Options:
  -v    Print verbose details of the airport.
  -l    Look up the ISO 3166 two-letter country code by country name.
  -i    Install a cron job to periodically update the DB.
  -s    Sync the local DB to the latest version.
  -h    Print this help message."
    }

    local OPTIND info result country iata city continent country_code name latitude longitude wiki
    local verbose=0
    local lookup=0
    while getopts ":ishlv" arg; do
        case $arg in
            i)  # install
                echo -e "$(command crontab -l)\n\n# Update IATA/country DB.\n$CRON_SCHEDULE $(command realpath "$0") -s" | command crontab - \
                    && error "installed cron tab" 0 \
                    || error "installation failed"
                return
                ;;
            s)  # sync
                download_iata_db "airports" \
                    && download_iata_db "countries" \
                    && error "synced DB" 0 \
                    || error "sync failed"
                return
                ;;
            h)  # help
                help && return
                ;;
            l)  # lookup
                lookup=1
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
    # Allow arguments to be passed after the input.
    while [[ "${@: -1}" =~ ^(-l|-v)$ ]] ; do
        if [[ "${@: -1}" == "-l" ]] ; then
            lookup=1
        elif [[ "${@: -1}" == "-v" ]] ; then
            verbose=1
        fi
        set -- "${@:1:$(($#-1))}"
    done

    if [[ $# -eq 0 ]] ; then
        error "missing input, please pass an airport code, country code, or city" 2
        return
    fi
    [[ ! -f "$DB_PATH/airports.csv" ]] && download_iata_db "airports"
    [[ ! -f "$DB_PATH/countries.csv" ]] && download_iata_db "countries"
    local input="${*^^}"

    if [[ $lookup -eq 1 ]] ; then  # lookup
        result="$(command awk -F, 'toupper($3) ~ /'"$input"'/ {gsub("\"", ""); OFS="  "; print $2, $3}' "$DB_PATH/countries.csv" \
            | command sort -k2
        )"
    else
        if [[ ${#input} -eq 2 ]] ; then  # country code
            result="$(country_code_to_name "$input")"
        elif [[ ${#input} -eq 3 ]] ; then  # IATA code
            info="$(airport_search "\"$input\"")"
            IFS=, read -r iata city continent country_code name latitude longitude wiki <<< "$info"
            country="$(country_code_to_name "$country_code")"
            if [[ -n "$info" ]] ; then
                if [[ $verbose -eq 0 ]] ; then
                    result="$city, $country"
                else
                    result="$(echo "iata|$iata
name|$name
city|$city
country|$country
continent|$continent
maps|https://www.google.com/maps/search/?api=1&query=$latitude%2C$longitude
wiki|$wiki" \
                        | command column -t -s"|"
                    )"
                fi
            fi
        else
            result="$(airport_search "$input" "case_insensitive" \
                | command cut -d, -f1,2,4,5 \
                | command sed -E 's/(...),(.*),(..),(.*)/\1\|\4\|\2, \3/g' \
                | command column -t -s"|" \
                | command sort -k2
            )"
        fi
    fi

    # I need exit code 1 if there's no match.
    echo "$result" | command grep .
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
TRACE_OUT="\$(command mktemp)"

exec 2>/dev/null
exec 3>"\$TRACE_OUT"
export BASH_XTRACEFD=3
PS4='+ \$EPOCHREALTIME\011(\${BASH_SOURCE}:\${LINENO}): \${FUNCNAME[0]:+\${FUNCNAME[0]}(): }'
set -x
$src_cmd
set +x

timestamp="\$(
    command grep -E '^\++\ [0-9]+' "\$TRACE_OUT" \
        | command awk 'NR>1 {OFMT="%f"; print p, \$2-p} {p=\$2}' \
        | command sort -k2 -nr \
        | command head -n1 \
        | command awk '{print \$1}'
)"
command grep -E "^\++\ \$timestamp.*" "\$TRACE_OUT" -B$CONTEXT_LINES -A$CONTEXT_LINES --color=always
command command rm "\$TRACE_OUT"
EOF
    command bash --noprofile --norc -il "$script_file"
    command rm "$script_file"
}
