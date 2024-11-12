#!/usr/bin/env bash

################################################################################
# Global variables
################################################################################

_NAME=$(command basename "$0")
if command ps -e | command grep -Eq "Xorg|wayland"; then
	HAS_GUI=1
else
	HAS_GUI=0
fi
if command lspci 2>/dev/null | command grep -iq nvidia; then
	HAS_NVIDIA=1
else
	HAS_NVIDIA=0
fi
if [[ $UID -eq 0 ]]; then
	HELP_ARG_USER=""
else
	HELP_ARG_USER=" [default: $USER]"
fi
HELP_DOC="Bootstrap machine.

Usage:
  $_NAME [options]

Options:
  --help                    Print help.
  --hostname <hostname>     Hostname to set the machine to. Optional.
  --keys <file>             SSH authorized keys file. Optional.
  --user <user>             Which user to initialize$HELP_ARG_USER."
TIME_ZONE="America/Los_Angeles"

################################################################################
# Helper methods
################################################################################

# Usage:
#       error <message> [<exit_code>]
error() {
	[[ $2 -eq 0 ]] && std_err_or_out=1 || std_err_or_out=2
	echo "$_NAME: $1" >&"$std_err_or_out"
	exit "${2:-1}"
}

################################################################################
# Validate input
################################################################################

for arg in "$@"; do
	case "$arg" in
	--help)
		echo "$HELP_DOC" && exit
		;;
	--hostname)
		HOST_NAME="$arg"
		;;
	--keys)
		KEYS_FILE="$arg"
		[[ ! -r "$KEYS_FILE" ]] && error "file '$KEYS_FILE' not found"
		[[ ! -s "$KEYS_FILE" ]] && error "file '$KEYS_FILE' empty"
		;;
	--user)
		USER_NAME="$arg"
		;;
	*)
		echo "$HELP_DOC" >&2 && exit 64 # EX_USAGE
		;;
	esac
done
if [[ $UID -eq 0 ]]; then
	[[ -z "$USER_NAME" ]] && error "please pass the user name with --user"
else
	[[ -z "$USER_NAME" ]] && USER_NAME="$USER"
fi

################################################################################
# Config before
################################################################################

# Cockpit
sudo dnf remove -y cockpit*
# DNF
if ! grep -q '^max_parallel_downloads' /etc/dnf/dnf.conf; then
	echo "max_parallel_downloads=20" | sudo tee -a /etc/dnf/dnf.conf
fi
# DNS
sudo tee /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::884
FallbackDNS=
Domains=~.
#DNSSEC=no
DNSOverTLS=yes
#MulticastDNS=no
#LLMNR=resolve
Cache=yes
#CacheFromLocalhost=no
#DNSStubListener=yes
#DNSStubListenerExtra=0.0.0.0
#DNSStubListenerExtra=::1
#ReadEtcHosts=yes
#ResolveUnicastSingleLabel=no
#StaleRetentionSec=0
EOF
sudo systemctl daemon-reload
sudo systemctl restart systemd-resolved
# Expand root partition
free_space="$(
	sudo vgs --rows |
		command grep 'VFree' |
		command awk '{print $2}'
)"
if [[ "$free_space" != "0" ]]; then
	logical_volume="$(
		command df -h |
			command grep /$ |
			command awk '{print $1}'
	)"
	sudo lvextend -r -l +100%FREE "$logical_volume"
fi
# Firewall
sudo systemctl disable --now firewalld
# Hostname
[[ -n "$HOST_NAME" ]] && sudo hostnamectl set-hostname "$HOST_NAME"
# SSH
[[ "$USER_NAME" != "$USER" ]] && command su "$USER_NAME"
if [[ -n "$KEYS_FILE" ]]; then
	command chmod 700 "$HOME"
	command mkdir "$HOME/.ssh"
	command chmod 700 "$HOME/.ssh"
	sudo cp "$KEYS_FILE" "$HOME/.ssh/authorized_keys"
	sudo chown "$USER_NAME": "$HOME/.ssh/authorized_keys"
	command chmod 600 "$HOME/.ssh/authorized_keys"
	sudo passwd -d root
	sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
fi
echo "PrintLastLog No" | sudo tee /etc/ssh/sshd_config.d/silent-login.conf
sudo systemctl daemon-reload
sudo systemctl reload sshd
# TCP
sudo tee /etc/sysctl.d/98-tcp.conf <<EOF
# allow TCP with buffers up to 64MB
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
# increase Linux autotuning TCP buffer limit to 32MB
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
# recommended for hosts with jumbo frames enabled
net.ipv4.tcp_mtu_probing=1
# BBR
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
sudo sysctl -p /etc/sysctl.d/98-tcp.conf
# Time zone
sudo timedatectl set-timezone "$TIME_ZONE"
# User
[[ -n "$USER_NAME" ]] && sudo useradd -m -G wheel "$USER_NAME"
if sudo grep -q '^# %wheel[[:space:]]\+ALL=(ALL)[[:space:]]\+NOPASSWD: ALL' /etc/sudoers; then
	sudo sed -i 's/^#\+[[:space:]]*%wheel[[:space:]]\+ALL=(ALL)[[:space:]]\+NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
	sudo sed -i 's/^%wheel[[:space:]]\+ALL=(ALL)[[:space:]]\+ALL/# %wheel ALL=(ALL) ALL/g' /etc/sudoers
fi

################################################################################
# CLI
################################################################################

# Docker
sudo rpm --import "https://download.docker.com/linux/fedora/gpg"
sudo dnf config-manager --add-repo "https://download.docker.com/linux/fedora/docker-ce.repo"
# Google Cloud CLI
sudo rpm --import "https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"
sudo tee /etc/yum.repos.d/google-cloud-sdk.repo <<EOF
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
# RPM Fusion
for repo in free nonfree; do
	sudo dnf install -y "https://mirrors.rpmfusion.org/$repo/fedora/rpmfusion-$repo-release-$(rpm -E %fedora).noarch.rpm"
done
# Tailscale
sudo rpm --import "https://pkgs.tailscale.com/stable/fedora/repo.gpg"
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo

sudo dnf upgrade -y

CLI_APPS=(
	aircrack-ng
	aria2
	bat
	bc
	bcc
	bind-utils
	binwalk
	calibre
	cargo
	certbot
	cksfv
	cmake
	containerd.io
	cronie
	datamash
	dnf-automatic
	dnsperf
	docker-ce
	docker-ce-cli
	docker-compose-plugin
	et
	ettercap
	expect
	fd-find
	ffmpeg
	fzf
	git
	git-extras
	golang
	google-cloud-cli
	hping3
	htop
	httpd-tools
	hydra
	iftop
	ImageMagick
	innoextract
	iperf3
	libnotify
	lynis
	mediainfo
	miller
	moreutils
	mtd-utils-ubi
	mtr
	mysql
	ncdu
	netcat
	nethogs
	netmask
	newt
	nfs-utils
	ngrep
	nmap
	nodejs
	nut
	oathtool
	openssl
	p7zip
	p7zip-plugins
	parallel
	perf
	plocate
	poppler
	prename
	pv
	pwgen
	python3-certbot-dns-google
	python3-devel
	python3-pip
	qrencode
	rclone
	ripgrep
	rust
	ShellCheck
	shfmt
	socat
	speedtest-cli
	sshpass
	tailscale
	telnet
	thefuck
	tmux
	tor
	translate-shell
	transmission-common
	tree
	uboot-tools
	unrar
	vim
	wireguard-tools
	wireshark-cli
	xq
)
sudo dnf install -y "${CLI_APPS[@]}" --allowerasing

SERVICES=(
	dnf-automatic.timer
	docker
	et
	fwupd-refresh.timer
	tailscaled
	tor
)
sudo systemctl enable --now "${SERVICES[@]}"

################################################################################
# GUI
################################################################################

if [[ $HAS_GUI -eq 1 ]]; then
	# 1Password
	sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
	sudo tee "/etc/yum.repos.d/1password.repo" >/dev/null <<EOF
[1password]
name="1Password Stable Channel"
baseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

	GUI_APPS=(
		1password
		gnome-tweaks
		google-chrome-stable
		kitty
		piper
		vlc
		wireshark
	)
	sudo dnf install -y "${GUI_APPS[@]}"
fi

################################################################################
# Nvidia
################################################################################

if [[ $HAS_NVIDIA -eq 1 ]]; then
	NVIDIA_APPS=(
		akmod-nvidia
		libva-utils
		nvidia-vaapi-driver
		vdpauinfo
		xorg-x11-drv-nvidia
		xorg-x11-drv-nvidia-cuda
		xorg-x11-drv-nvidia-cuda-libs
	)
	sudo dnf install -y "${NVIDIA_APPS[@]}"
	# To account for a bug where autoremove might wrongly remove the package.
	sudo dnf mark install akmod-nvidia
fi

################################################################################
# Languages
################################################################################

for lang in golang node python rust; do
	command bash "$(command dirname "$0")/lib/$lang.sh"
done

################################################################################
# Config after
################################################################################

# Docker
[[ $UID -ne 0 ]] && sudo usermod -aG docker "$USER"
[[ ! -r /etc/docker/daemon.json ]] && echo "{}" | sudo tee /etc/docker/daemon.json
command jq '.["metrics-addr"] = "0.0.0.0:9323"' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json
sudo systemctl reload docker
# Tailscale
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off \n' "$(
	command ip -o route get 8.8.8.8 |
		command cut -f 5 -d " "
)" |
	sudo tee /etc/NetworkManager/dispatcher.d/pre-up.d/50-tailscale
sudo chmod 755 /etc/NetworkManager/dispatcher.d/pre-up.d/50-tailscale
sudo /etc/NetworkManager/dispatcher.d/pre-up.d/50-tailscale
if grep -q '^FLAGS=""' /etc/default/tailscaled; then
	sudo sed -i 's/^FLAGS=""/FLAGS="--debug=0.0.0.0:1234"/g' /etc/default/tailscaled
fi
