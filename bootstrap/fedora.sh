#!/usr/bin/env bash

# Load third-party repositories.
# 1Password
sudo tee "/etc/yum.repos.d/1password.repo" >/dev/null <<EOF
[1password]
name="1Password Stable Channel"
baseurl=https://downloads.1password.com/linux/rpm/stable/x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
# Docker
sudo dnf config-manager --add-repo "https://download.docker.com/linux/fedora/docker-ce.repo"
sudo rpm --import "https://download.docker.com/linux/fedora/gpg"
# Google Cloud CLI
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo <<EOF
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
# Google Chrome
sudo tee "/etc/yum.repos.d/google-chrome.repo" >/dev/null <<EOF
[google-chrome]
name=Google Chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
# RPM Fusion
for repo in free nonfree; do
	sudo dnf install -y "https://mirrors.rpmfusion.org/$repo/fedora/rpmfusion-$repo-release-$(rpm -E %fedora).noarch.rpm"
done
# Tailscale
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo rpm --import "https://pkgs.tailscale.com/stable/fedora/repo.gpg"
# TICK stack
sudo tee /etc/yum.repos.d/influxdb.repo <<EOF
[influxdb]
name = InfluxData Repository - Stable
baseurl = https://repos.influxdata.com/stable/\$basearch/main
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdata-archive_compat.key
EOF
# Update all installed packages.
sudo dnf upgrade -y

# Install CLI apps.
CLI_APPS=(
	aircrack-ng
	aria2
	bat
	bc
	bcc
	bind-utils
	calibre
	cargo
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
	iperf3
	libnotify
	lynis
	mediainfo
	miller
	moreutils
	mtr
	ncdu
	netcat
	nethogs
	netmask
	newt
	nfs-utils
	ngrep
	nmap
	nodejs
	oathtool
	p7zip
	p7zip-plugins
	parallel
	perf
	plocate
	poppler
	prename
	pv
	pwgen
	python3-devel
	python3-pip
	qrencode
	rclone
	ripgrep
	rsyslog
	rust
	ShellCheck
	shfmt
	socat
	speedtest-cli
	telnet
	thefuck
	tmux
	tor
	transmission-common
	tree
	unrar
	vim
	wireguard-tools
	wireshark-cli
	xq
)
sudo dnf install -y "${CLI_APPS[@]}"

# Install GUI apps.
GUI_APPS=(
	1password
	akmod-nvidia
	gnome-tweaks
	google-chrome-stable
	kitty
	piper
	vlc
	wireshark
	xorg-x11-drv-nvidia-cuda
)
sudo dnf install -y "${GUI_APPS[@]}"

# Configure services.
# Auto-start on booting up.
SERVICES=(
	containerd
	dnf-automatic.timer
	docker
	et
	rsyslog
	tailscaled
	tor
)
sudo systemctl enable --now "${SERVICES[@]}"
# Interact with Docker daemon without sudo.
sudo usermod -aG docker "$USER"
