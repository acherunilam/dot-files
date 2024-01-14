# shellcheck shell=bash


# Load ACME (https://github.com/acmesh-official/acme.sh), an ACME protocol client.
include "$HOME/.acme.sh/acme.sh.env"


# Load BCC (https://github.com/iovisor/bcc), a toolkit for creating efficient
# kernel tracing and manipulation programs.
#
# Dependencies:
#       dnf install bcc
export PATH="/usr/share/bcc/tools:$PATH"


# Configure helpers for Tor (https://www.torproject.org), an anonymous overlay network.
alias tor-curl='curl -qsS --location --proxy socks5://localhost:9050'                       # curl through Tor
alias tor-cycle='sudo killall -HUP tor'                                                     # change the Tor exit node
alias tor-ip='curl-time --proxy socks5://localhost:9050 "https://checkip.amazonaws.com"'    # check the outbound IP for your Tor setup


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
curly() {
    curl-time --output /dev/null "$@" | command sed '/^$/d'
}


# Flush the OS-level DNS cache.
#
# Usage:
#       dns-flush
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


# Identify the bottleneck in the shell startup time by profiling your dot files. If the
# dot file isn't specified, it defaults to sourcing both /etc/profile and ~/.bashrc.
#
# Usage:
#       profile [<dot_file>]
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


# Open a DNS tunnel using Iodine (https://github.com/yarrick/iodine).
#
# Environment variables:
#       export TUNNEL_DNS_DOMAIN="<server-domain>"
#       export TUNNEL_DNS_PASSWORD="<password>"
tunnel-dns() {
	validate-env "TUNNEL_DNS_DOMAIN" "TUNNEL_DNS_PASSWORD" || return
	sudo iodine -f -P "$TUNNEL_DNS_PASSWORD" "$TUNNEL_DNS_DOMAIN"
}


# Open an ICMP tunnel using Hans (https://github.com/friedrich/hans).
#
# Environment variables:
#       export TUNNEL_ICMP_IP="<server-ip>"
#       export TUNNEL_ICMP_PASSWORD="<password>"
tunnel-icmp() {
	validate-env "TUNNEL_ICMP_IP" "TUNNEL_ICMP_PASSWORD" || return
	sudo hans -f -c "$TUNNEL_ICMP_IP" -p "$TUNNEL_ICMP_PASSWORD"
}


# Switch Tailscale exit node.
#
# Usage:
#		ts [<exit_node_alias>]
#
# Environment variables:
#       export TAILSCALE_EXIT_NODES='(["alias2"]="node1" ["alias2"]="node2")'
ts() {
    local NODE
    declare -A tailscale_nodes=$TAILSCALE_EXIT_NODES
    [[ -n "$1" ]] && NODE="${tailscale_nodes[$1]}"
	sudo tailscale up --exit-node="$NODE"
}
