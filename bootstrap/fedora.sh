#!/usr/bin/env bash

################################################################################
# Global variables.
################################################################################

_NAME=$(basename "$0")
if compgen -G '/usr/share/wayland-sessions/*.desktop' >/dev/null ||
	compgen -G '/usr/share/xsessions/*.desktop' >/dev/null; then
	HAS_GUI=1
else
	HAS_GUI=0
fi
if grep -qs 0x10de /sys/bus/pci/devices/*/vendor; then
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
# Helper methods.
################################################################################

# Usage:
#       error <message> [<exit_code>]
error() {
	[[ ${2:-1} -eq 0 ]] && std_err_or_out=1 || std_err_or_out=2
	echo "$_NAME: $1" >&"$std_err_or_out"
	exit "${2:-1}"
}

################################################################################
# Validate input.
################################################################################

while (($#)); do
	case "$1" in
	--help)
		echo "$HELP_DOC" && exit
		;;
	--hostname | --keys | --user)
		[[ -z "$2" ]] && error "option '$1' requires a value" 64 # EX_USAGE
		;;&
	--hostname)
		HOST_NAME="$2"
		shift
		;;
	--keys)
		KEYS_FILE="$2"
		[[ ! -r "$KEYS_FILE" ]] && error "file '$KEYS_FILE' not found" 66 # EX_NOINPUT
		[[ ! -s "$KEYS_FILE" ]] && error "file '$KEYS_FILE' empty" 65 # EX_DATAERR
		shift
		;;
	--user)
		USER_NAME="$2"
		shift
		;;
	*)
		echo "$HELP_DOC" >&2 && exit 64 # EX_USAGE
		;;
	esac
	shift
done
if [[ $UID -eq 0 ]]; then
	[[ -z "$USER_NAME" ]] && error "please pass the user name with --user" 64 # EX_USAGE
else
	[[ -z "$USER_NAME" ]] && USER_NAME="$USER"
fi

################################################################################
# Config before.
################################################################################

# Cockpit
sudo dnf remove -y 'cockpit*'
# DNF
if ! grep -q '^max_parallel_downloads' /etc/dnf/dnf.conf; then
	echo "max_parallel_downloads=20" | sudo tee -a /etc/dnf/dnf.conf
fi
# DNS
sudo tee /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844
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
	sudo vgs --rows 2>/dev/null |
		grep 'VFree' |
		awk '{print $2}'
)"
if [[ -n "$free_space" && "$free_space" != "0" ]]; then
	logical_volume="$(findmnt -no SOURCE /)"
	sudo lvextend -r -l +100%FREE "$logical_volume"
fi
# Firewall
sudo systemctl disable --now firewalld
# Hostname
[[ -n "$HOST_NAME" ]] && sudo hostnamectl set-hostname "$HOST_NAME"
# User
if ! id "$USER_NAME" &>/dev/null; then
	sudo useradd -m -G wheel "$USER_NAME"
fi
# SSH
if [[ -n "$KEYS_FILE" ]]; then
	user_home="$(getent passwd "$USER_NAME" | cut -d: -f6)"
	sudo chmod 700 "$user_home"
	sudo mkdir -p "$user_home/.ssh"
	sudo cp "$KEYS_FILE" "$user_home/.ssh/authorized_keys"
	sudo chown -R "$USER_NAME": "$user_home/.ssh"
	sudo chmod 700 "$user_home/.ssh"
	sudo chmod 600 "$user_home/.ssh/authorized_keys"
	sudo passwd -l root
	echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/00-root-login.conf
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
# Sudo
echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/wheel
sudo chmod 440 /etc/sudoers.d/wheel
sudo visudo -cf /etc/sudoers.d/wheel || sudo rm -f /etc/sudoers.d/wheel

################################################################################
# CLI.
################################################################################

# Docker
sudo rpm --import "https://download.docker.com/linux/fedora/gpg"
sudo dnf config-manager addrepo --overwrite --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
# Filebot
sudo dnf config-manager addrepo --overwrite --id=filebot \
	--set=name=filebot \
	--set=baseurl=https://get.filebot.net/rpm/main/x86_64 \
	--set=skip_if_unavailable=1 \
	--set=gpgcheck=0
# Google Cloud CLI
sudo rpm --import "https://packages.cloud.google.com/yum/doc/rpm-package-key-v10.gpg"
sudo dnf config-manager addrepo --overwrite --id=google-cloud-cli --save-filename=google-cloud-sdk \
	--set=name="Google Cloud CLI" \
	--set=baseurl='https://packages.cloud.google.com/yum/repos/cloud-sdk-el10-$basearch' \
	--set=gpgcheck=1 \
	--set=repo_gpgcheck=0 \
	--set=gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key-v10.gpg
# RPM Fusion
for repo in free nonfree; do
	sudo dnf install -y "https://mirrors.rpmfusion.org/$repo/fedora/rpmfusion-$repo-release-$(rpm -E %fedora).noarch.rpm" ||
		error "RPM Fusion $repo install failed"
done
# Tailscale
sudo rpm --import "https://pkgs.tailscale.com/stable/fedora/repo.gpg"
sudo dnf config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

sudo dnf upgrade -y

CLI_APPS=(
	7zip
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
	dnf5-plugin-automatic
	dnsperf
	docker-buildx-plugin
	docker-ce
	docker-ce-cli
	docker-compose-plugin
	et
	ethtool
	ettercap
	expect
	fd-find
	ffmpeg
	filebot
	fzf
	git
	git-extras
	golang
	google-cloud-cli
	htop
	httpd-tools
	hydra
	iftop
	ImageMagick
	innoextract
	intel-media-driver
	iperf3
	jq
	libnotify
	libva-utils
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
	parallel
	perf
	pipx
	plocate
	poppler
	prename
	progress
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
	vim-enhanced
	whois
	wireguard-tools
	wireshark-cli
	xq
	yt-dlp
	zoxide
)
sudo dnf install -y "${CLI_APPS[@]}" --allowerasing ||
	error "CLI package install failed"

SERVICES=(
	crond
	dnf5-automatic.timer
	docker
	et
	fwupd-refresh.timer
	tailscaled
	tor
)
sudo systemctl enable --now "${SERVICES[@]}"

################################################################################
# GUI.
################################################################################

if [[ $HAS_GUI -eq 1 ]]; then
	# 1Password
	sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
	sudo dnf config-manager addrepo --overwrite --id=1password \
		--set=name="1Password Stable Channel" \
		--set=baseurl='https://downloads.1password.com/linux/rpm/stable/$basearch' \
		--set=gpgcheck=1 \
		--set=repo_gpgcheck=1 \
		--set=gpgkey=https://downloads.1password.com/linux/keys/1password.asc
	# Google Chrome
	sudo dnf install -y fedora-workstation-repositories ||
		error "Google Chrome repo install failed"
	sudo dnf config-manager setopt google-chrome.enabled=1

	GUI_APPS=(
		1password
		gnome-tweaks
		google-chrome-stable
		kitty
		piper
		vlc
		wireshark
	)
	sudo dnf install -y "${GUI_APPS[@]}" ||
		error "GUI package install failed"
fi

################################################################################
# Nvidia.
################################################################################

if [[ $HAS_NVIDIA -eq 1 ]]; then
	NVIDIA_APPS=(
		akmod-nvidia
		libva-nvidia-driver
		vdpauinfo
		xorg-x11-drv-nvidia
		xorg-x11-drv-nvidia-cuda
		xorg-x11-drv-nvidia-cuda-libs
	)
	sudo dnf install -y "${NVIDIA_APPS[@]}" ||
		error "Nvidia package install failed"
	# To account for a bug where autoremove might wrongly remove the package.
	sudo dnf mark install akmod-nvidia
fi

################################################################################
# Languages.
################################################################################

for lang in golang node python rust; do
	# shellcheck disable=SC2024
	sudo -iu "$USER_NAME" bash -s <"$(dirname "$0")/lib/$lang.sh" ||
		error "$lang install failed"
done

################################################################################
# Config after.
################################################################################

# DNF
if [[ -r /etc/dnf/automatic.conf ]]; then
	sudo sed -i 's/^apply_updates\s*=\s*no/apply_updates = yes/' /etc/dnf/automatic.conf
else
	printf '[commands]\napply_updates = yes\n' | sudo tee /etc/dnf/automatic.conf
fi
# Docker
sudo usermod -aG docker "$USER_NAME"
[[ ! -r /etc/docker/daemon.json ]] && echo "{}" | sudo tee /etc/docker/daemon.json
daemon_json="$(jq '
	.["metrics-addr"] = "0.0.0.0:9323" |
	.["log-driver"] = "json-file" |
	.["log-opts"] = {"max-size": "10m", "max-file": "3"}
' /etc/docker/daemon.json)"
if [[ "$daemon_json" != "$(cat /etc/docker/daemon.json)" ]]; then
	echo "$daemon_json" | sudo tee /etc/docker/daemon.json
	sudo systemctl restart docker
elif ! ss -tulpn | grep -q :9323; then
	sudo systemctl restart docker
fi
# Tailscale
sudo tee /etc/sysctl.d/99-tailscale.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off \n' "$(
	ip -o route get 8.8.8.8 |
		cut -f 5 -d " "
)" |
	sudo tee /etc/NetworkManager/dispatcher.d/pre-up.d/50-tailscale
sudo chmod 755 /etc/NetworkManager/dispatcher.d/pre-up.d/50-tailscale
sudo /etc/NetworkManager/dispatcher.d/pre-up.d/50-tailscale
sudo tailscale set --webclient
