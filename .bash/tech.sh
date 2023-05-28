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


alias scl='sudo systemctl'                                                                  # Systemd inspection.
alias tor-curl='curl -qsS --location --proxy socks5://localhost:9050'                       # Curl through Tor.
alias tor-cycle='sudo killall -HUP tor'                                                     # Change the Tor exit node.
alias tor-ip='curl-time --proxy socks5://localhost:9050 "https://checkip.amazonaws.com"'    # Check the outbound IP for your Tor setup.


# Prints the AS details for the given IP or ASN.
#
# Usage:
#       asn <ip_address>
#       asn <as_number> [-p]
#
# Options:
#       -p      List all prefixes for the ASN.
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
            echo "$input" | command sed -E "s/::/:$(command yes "0:" \
                | command head -n $((8 - hextets)) 2>/dev/null | paste -sd '')/g;s/^://g;s/:$//g"
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


# Print the X.509 TLS certificate details.
#
# Usage:
#       cert <host>[:<port>] [<sni>]
cert() {
    local DST="$1"
    local SNI="${2:-${1%:*}}"
    [[ "$DST" != *":"* ]] && DST="$DST:443"
    echo \
        | command openssl s_client -showcerts -servername "$SNI" -connect "$DST" 2>/dev/null \
        | command openssl x509 -noout -text
}


# Benchmark how long it takes for your curl query to finish.
#
# Usage:
#       curl-time [<options>...] <url>
curl-time() {
    command curl -qsS --location --fail "$@" --write-out "
dns         %{time_namelookup}
tcp         %{time_connect}
tls         %{time_appconnect} (fail=%{ssl_verify_result})
req sent    %{time_pretransfer} (%{size_request} bytes)
redir       %{time_redirect} (%{num_redirects} redirs)
first byte  %{time_starttransfer} (HTTP %{response_code})
last byte   %{time_total} (%{num_connects} connect(s), rx: %{size_download} bytes / tx: %{size_upload} bytes)
"
}


# Silently benchmark Curl.
#
# Usage:
#       curly [<options>...] <url>
#
# Dependencies:
#       curl-time()
curly() {
    curl-time --output /dev/null "$@" | command sed '/^$/d'
}


# Flushes the OS-level DNS cache.
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2155
dns-flush() {
    if [[ "$OSTYPE" == "darwin"* ]] ; then
        sudo command killall -HUP mDNSResponder
        sudo command killall mDNSResponderHelper
        sudo command dscacheutil -flushcache
        return
    fi
    local is_systemd_resolved="$(command systemctl is-active systemd-resolved 2>/dev/null)"
    if [[ "$is_systemd_resolved" == "active" ]] ; then
        sudo command systemd-resolve --flush-caches
    else
        error "error, only systemd-resolved is supported on Linux" ; return
    fi
}


# Prints geolocation information for an IP address using IPinfo (https://ipinfo.io).
# The API token can be viewed over here (https://ipinfo.io/account/token).
#
# Usage:
#       geo <ip_address> [-l]
#       geo (-i | -s)
#
# Options:
#       -l      Reads from the local MMDB instead of malking external API call.
#               This omits extra info like city, hostname, is_anycast, etc.
#       -i      Installs a cron job to periodically update the MMDB.
#       -s      Syncs the local MMDB to the latest version.
#
# Environment variables:
#       export IPINFO_API_TOKEN="<api_token>"
#
# Dependencies:
#       dnf install jq
#       go install github.com/ipinfo/mmdbctl@latest
#       error()
#       validate-env()
#
# shellcheck disable=SC2015,SC2199
geo() {
    local CRON_SCHEDULE="0 5 * * 1"  # every Mon 5 AM
    local DB_PATH="$HOME/.local/share/geo/country_asn.mmdb"

    download_mmdb() {
        command curl -qsS --connect-timeout 2 --max-time 30 -L \
            "https://ipinfo.io/data/free/country_asn.mmdb?token=$IPINFO_API_TOKEN" --create-dirs -o "$DB_PATH.new"
        if command grep -aq "per day limit" "$DB_PATH.new" 2>/dev/null ; then
            command rm "$DB_PATH.new"
            error "download failed, per day limit reached"
        else
            command mv "$DB_PATH.new" "$DB_PATH" 2>/dev/null
        fi
    }

    help() {
        echo "Usage: ${FUNCNAME[1]} <ip_address> [-l]
       ${FUNCNAME[1]} (-i | -s)
Prints geolocation information for an IP address.

Options:
  -l    Read from the local MMDB instead of malking external API call.
        This omits extra info like city, hostname, is_anycast, etc.
  -i    Install a cron job to periodically update the MMDB.
  -s    Sync the local MMDB to the latest version.
  -h    Print this help message."
    }

    local OPTIND
    local local=0
    while getopts ":ishl" arg; do
        case $arg in
            i)  # install
                echo -e "$(command crontab -l)\n\n# Update gelocation MMDB.\n$CRON_SCHEDULE $SHELL -ic '${FUNCNAME[0]} -s'" | command crontab - \
                    && error "installed cron tab" 0 \
                    || error "installation failed"
                return
                ;;
            s)  # sync
                validate-env "IPINFO_API_TOKEN" || return
                download_mmdb \
                    && error "synced DB" 0 \
                    || error "sync failed"
                return
                ;;
            h)  # help
                help && return
                ;;
            l)  # local
                local=1
                ;;
            *)
                help >&2 && return 2
                ;;
        esac
    done
    shift $((OPTIND-1))
    # Allow arguments to be passed after the input.
    if [[ "${@: -1}" == "-l" ]] ; then
        local=1
        set -- "${@:1:$(($#-1))}"
    fi
    if [[ $# -eq 0 ]] ; then
        error "missing input, please pass an IP address" 2
        return
    elif [[ $# -gt 1 ]] ; then
        error "do not pass more than one IP address" 2 ; return
    fi
    local ip_addr="$1"

    if [[ $local -eq 1 ]] ; then  # MMDB
        if [[ ! -f "$DB_PATH" ]] ; then
            validate-env "IPINFO_API_TOKEN" || return
            download_mmdb || return
        fi
        echo "$ip_addr" | command mmdbctl read "$DB_PATH" | command jq '.'
    else # external API
        command curl -qsS --connect-timeout 2 --max-time 5 "https://ipinfo.io/$ip_addr?token=$IPINFO_API_TOKEN" \
            | command jq '.'
    fi
}


# Prints the details of the IATA airport code or country code using Team
# Cymru (https://www.team-cymru.com/ip-asn-mapping).
#
# Usage:
#       iata <airport_code> [-v]
#       iata <airport_name>
#       iata <country_code>
#       iata <country_name> -c
#       iata (-i | -s)
#
# Options:
#       -v      Prints verbose details of the airport.
#       -c      Looks up country code by the country name.
#       -i      Installs a cron job to periodically update the DB.
#       -s      Syncs the local IATA DB to the latest version.
#
# Dependencies:
#       dnf install util-linux
#       error()
#
# shellcheck disable=SC2015,SC2016,SC2086,SC2199
iata() {
    local CRON_SCHEDULE="0 5 * * 1"  # every Mon 5 AM
    local DB_PATH="$HOME/.local/share/iata"

    airport_search() {
        [[ -n "$2" ]] && opts="-i"
        command grep $opts "$1" "$DB_PATH/airports.csv" \
            | command awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", "~", $i) } 1' \
            | command awk -F, '{gsub("\"", ""); OFS=","; print $14, $11, $8, $9, $4, $5, $6, $17}' \
            | command grep -v '^,'
    }

    country_code_to_name() {
        command awk -F, '$2 == "\"'"$1"'\"" {gsub("\"", ""); print $3}' "$DB_PATH/countries.csv"
    }

    download_iata_db() {
        command curl -qsS --connect-timeout 2 --max-time 60 \
            "https://raw.githubusercontent.com/davidmegginson/ourairports-data/main/$1.csv" --create-dirs -o "$DB_PATH/$1.csv.new"
        if command head -n1 "$DB_PATH/$1.csv.new" 2>/dev/null | command grep -aq '"name"' ; then
            command mv "$DB_PATH/$1.csv.new" "$DB_PATH/$1.csv"
        else
            command rm -f "$DB_PATH/$1.csv.new"
            error "download failed"
        fi
    }

    help() {
        echo "Usage: ${FUNCNAME[1]} <airport_code> [-v]
       ${FUNCNAME[1]} <airport_name>
       ${FUNCNAME[1]} <country_code>
       ${FUNCNAME[1]} <country_name> -c
       ${FUNCNAME[1]} (-i | -s)
Prints the details of the IATA airport code or country code.

Options:
  -v    Print verbose details of the airport.
  -c    Look up the ISO 3166 two-letter country code by country name.
  -i    Install a cron job to periodically update the DB.
  -s    Sync the local DB to the latest version.
  -h    Print this help message."
    }

    local OPTIND info result country iata city continent country_code name latitude longitude wiki
    local verbose=0
    local country=0
    while getopts ":ishcv" arg; do
        case $arg in
            i)  # install
                echo -e "$(command crontab -l)\n\n# Update IATA/country DB.\n$CRON_SCHEDULE $SHELL -ic '${FUNCNAME[0]} -s'" | command crontab - \
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
            c)  # country
                country=1
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
    while [[ "${@: -1}" =~ ^(-c|-v)$ ]] ; do
        if [[ "${@: -1}" == "-c" ]] ; then
            country=1
        elif [[ "${@: -1}" == "-v" ]] ; then
            verbose=1
        fi
        set -- "${@:1:$(($#-1))}"
    done

    if [[ $# -eq 0 ]] ; then
        error "missing input, please pass an airport code, country code, or city" 2
        return
    fi
    if [[ ! -f "$DB_PATH/airports.csv" ]] ; then
        download_iata_db "airports" || return
    fi
    if [[ ! -f "$DB_PATH/countries.csv" ]] ; then
        download_iata_db "countries" || return
    fi
    local input="${*^^}"

    if [[ $country -eq 1 ]] ; then  # country
        result="$(command awk -F, 'toupper($3) ~ /'"$input"'/ {gsub("\"", ""); OFS="  "; print $2, $3}' "$DB_PATH/countries.csv" \
            | command sort -k2
        )"
    else
        if [[ ${#input} -eq 2 ]] ; then  # country code
            result="$(country_code_to_name "$input")"
        elif [[ ${#input} -eq 3 ]] ; then  # IATA code
            info="$(airport_search "\"$input\"" \
                | command grep "^$input,"
            )"
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
    echo "$result" | command sed 's/~/,/g' | command grep .
}


# Looks up the vendor for the given MAC ID.
#
# Usage:
#       mac-lookup <mac_id>
#
# Dependencies:
#       error()
#
# shellcheck disable=SC2181
mac-lookup() {
    local MAC_ID="${1^^}"
    if [[ -z "$MAC_ID" ]]; then
        error "please pass the MAC ID" ; return
    elif [[ $# -gt 1 ]] ; then
        error "do not pass more than one MAC ID"
    elif [[ ! "$MAC_ID" =~ ^([0-9A-F]{2}[:-]?){5}([0-9A-F]{2})$ ]] ; then
        error "invalid MAC ID" ; return
    fi
    MAC_ID="$(command sed -E 's/(-|:)//g' <<< "$MAC_ID")"
    local OUI_DB_URL="https://standards-oui.ieee.org/oui/oui.txt"
    local DB_PATH="$HOME/.local/share/mac-lookup/oui.txt"
    if [[ ! -f "$DB_PATH" ]] ; then
        command curl -qsS --connect-timeout 2 --max-time 5 "$OUI_DB_URL" --create-dirs -o "$DB_PATH"
        if [[ $? -ne 0 ]] ; then
            error "unable to connect to $OUI_DB_URL" ; return
        fi
    fi
    command cat "$DB_PATH" \
        | command grep "${MAC_ID:0:6}" \
        | command sed -E 's/.*\(base 16\)\s+(.*)/\1/g' \
        | command grep .
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
    if [[ -z "$BASH_VERSION" ]] ; then
        error "your shell $SHELL is unsupported" ; return
    elif [[ $(echo "$BASH_VERSION" | command cut -d'.' -f1-2 | command tr -d '.') -lt 42 ]] ; then
        error "Bash version $BASH_VERSION is too old, cannot redirect trace output" ; return
    fi
    if [[ $# -eq 0 ]] ; then
        src_cmd="source /etc/profile ; source ~/.bashrc"
    elif [[ $# -gt 1 ]] ; then
        error "do not specify more than one dot file" 2 ; return
    elif [[ ! -f "$1" ]] ; then
        error "'$1' is not a sourceable file" 2 ; return
    else
        src_cmd="source $1"
    fi
    local CONTEXT_LINES=2
    local script_file="$(command mktemp)"
    cat <<EOF >"$script_file"
TRACE_OUT="\$(command mktemp)"

exec 2>/dev/null
exec 7>"\$TRACE_OUT"
export BASH_XTRACEFD=7
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
command rm "\$TRACE_OUT"
EOF
    command bash --noprofile --norc -il "$script_file"
    command rm "$script_file"
}


# Counts the number of active RIPE Atlas probes (https://atlas.ripe.net/about/) for the
# given country or ASN. The API key can generated over here (https://atlas.ripe.net/keys/).
#
# Usage:
#       ripe-atlas-probe (<country>|<asn>)
#
# Environment variables:
#       export ATLAS_CREATE_KEY="<api_key>"
#
# Dependencies:
#       pip install ripe.atlas.tools
#       error()
#       validate-env()
ripe-atlas-probe() {
    local INPUT="${1,,}"
    local FILTER_BY="country"
    local PROBE_SEARCH_LIMIT=10000
    if [[ $# -eq 0 ]] ; then
        error "please provide a country or ASN" 2 ; return
    elif [[ $# -gt 1 ]] ; then
        error "do not specify more than one country or ASN" 2 ; return
    elif [[ "$INPUT" =~ ^(asn?)?[0-9]+$ ]] ; then
        FILTER_BY="asn"
        INPUT="$(echo "$INPUT" | command sed -E 's/^asn?//g')"
    elif [[ ! "$INPUT" =~ ^[a-z]{2}$ ]] ; then
        error "'$INPUT' is not a valid country or ASN" 2 ; return
    fi
    validate-env "ATLAS_CREATE_KEY" || return
    command ripe-atlas probe-search --limit "$PROBE_SEARCH_LIMIT" \
            --"$FILTER_BY" "$INPUT" --status 1 --ids-only \
        | command wc -l \
        | command awk '{print $1}'
}


# Fetches the RIPE Atlas (https://atlas.ripe.net/about/) report for the given measurement ID.
#
# Usage:
#       ripe-atlas-report <id>
#
# Environment variables:
#       export ATLAS_CREATE_KEY="<api_key>"
#
# Dependencies:
#       dnf install jq
#       error()
#       validate-env()
ripe-atlas-report() {
    local RIPE_MEASUREMENT_ID="$1"
    if [[ $# -eq 0 ]] ; then
        error "please provide a measurement ID" 2 ; return
    elif [[ $# -gt 1 ]] ; then
        error "do not specify more than one measurement ID" 2 ; return
    elif [[ ! "$RIPE_MEASUREMENT_ID" =~ ^[0-9]+$ ]] ; then
        error "'$RIPE_MEASUREMENT_ID' is not a valid measurement ID" 2 ; return
    fi
    validate-env "ATLAS_CREATE_KEY" || return
    command curl -qsS -H "Authorization: Key $ATLAS_CREATE_KEY" \
            "https://atlas.ripe.net/api/v2/measurements/$RIPE_MEASUREMENT_ID/results" \
        | command jq '.'
}


# Runs traceroute using RIPE Atlas probes (https://atlas.ripe.net/about/).
#
# Usage:
#       ripe-atlas-trace <destination> [ww|<country>|<asn>] [<probe_count>]
#
# Environment variables:
#       export ATLAS_CREATE_KEY="<api_key>"
#
# Dependencies:
#       error()
#       validate-env()
ripe-atlas-trace() {
    local DST="$1"
    local FILTER_BY="area"
    local FILTER_VALUE="${2:-WW}"
    FILTER_VALUE="${FILTER_VALUE^^}"
    local PROBE_COUNT="${3:-10}"
    if [[ $# -eq 0 ]] ; then
        error "please provide a destination hostname or IP" 2 ; return
    elif [[ $# -gt 3 ]] ; then
        error "do not specify more than 3 arguments" 2 ; return
    elif [[ "$FILTER_VALUE" =~ ^(asn?)?[0-9]+$ ]] ; then
        FILTER_BY="asn"
        FILTER_VALUE="$(echo "$FILTER_VALUE" | command sed -E 's/^ASN?//g')"
    elif [[ "$FILTER_VALUE" =~ ^[A-Z]{2}$ ]] && [[ "$FILTER_VALUE" != "WW" ]] ; then
        FILTER_BY="country"
    elif [[ "$FILTER_VALUE" != "WW" ]] ; then
        error "'$FILTER_VALUE' is not a valid country or ASN" 2 ; return
    fi
    validate-env "ATLAS_CREATE_KEY" || return
    command ripe-atlas measure traceroute "$DST" \
        --description "[traceroute] [$FILTER_VALUE] $DST" \
        --from-"$FILTER_BY" "$FILTER_VALUE" \
        --probes "$PROBE_COUNT" \
        --resolve-on-probe \
        --no-report
}


# Switch Tailscale exit node.
#
# Usage:
#		ts [<exit_node_hostname>]
#
# Environment variables:
#       export TAILSCALE_EXIT_NODES=("node1" "node2")
ts() {
	local NODE="$1"
	sudo tailscale up --exit-node="$NODE"
}
