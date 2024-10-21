#!/usr/bin/env bash

################################################################################
# Global variables
################################################################################

# TODO: Ensure that it's not running as root.
if command ps -e | command grep -Eq "Xorg|wayland"; then
	HAS_GUI=1
else
	HAS_GUI=0
fi
if command lspci | grep -iq nvidia; then
	HAS_NVIDIA=1
else
	HAS_NVIDIA=0
fi

################################################################################
# CLI
################################################################################

# Docker
sudo rpm --import "https://download.docker.com/linux/fedora/gpg"
sudo dnf config-manager --add-repo "https://download.docker.com/linux/fedora/docker-ce.repo"
# Google Cloud CLI
sudo rpm --import "https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo <<EOF
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
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
# TICK stack
sudo rpm --import "https://repos.influxdata.com/influxdata-archive.key"
sudo tee /etc/yum.repos.d/influxdata.repo <<EOF
[influxdata]
name = InfluxData Repository - Stable
baseurl = https://repos.influxdata.com/stable/\$basearch/main
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdata-archive.key
EOF

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
sudo dnf install -y "${CLI_APPS[@]}"

SERVICES=(
	dnf-automatic.timer
	docker
	et
	fwupd-refresh.timer
	rsyslog
	tailscaled
	tor
)
sudo systemctl enable --now "${SERVICES[@]}"
sudo usermod -aG docker "$USER"

################################################################################
# GUI
################################################################################

if [[ $HAS_GUI -eq 1 ]]; then
	# 1Password
	sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
	sudo tee "/etc/yum.repos.d/1password.repo" >/dev/null <<EOF
[1password]
name="1Password Stable Channel"
baseurl=https://downloads.1password.com/linux/rpm/stable/x86_64
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
# Config
################################################################################

# sudo hostnamectl set-hostname "$HOST_NAME"
if sudo grep -q '^# %wheel[[:space:]]\+ALL=(ALL)[[:space:]]\+NOPASSWD: ALL' /etc/sudoers; then
	sudo sed -i 's/^# %wheel[[:space:]]\+ALL=(ALL)[[:space:]]\+NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
	sudo sed -i 's/^%wheel[[:space:]]\+ALL=(ALL)[[:space:]]\+ALL/# %wheel ALL=(ALL) ALL/g' /etc/sudoers
fi
sudo systemctl disable firewalld
sudo dnf remove cockpit*
sudo command sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
echo "PrintLastLog No" | sudo tee /etc/ssh/sshd_config.d/silent-login.conf
sudo systemctl daemon-reload
sudo systemctl reload sshd
# sudo useradd -m -G wheel "$USER_NAME"
# sudo passwd -d root
