# shellcheck shell=bash
# shellcheck disable=SC1091


# Load ACME client settings to renew Let's Encrypt certs.
#
# Dependencies:
#       curl https://get.acme.sh | sh -s email=my@example.com
[[ -f "$HOME/.acme.sh/acme.sh.env" ]] && source "$HOME/.acme.sh/acme.sh.env"
