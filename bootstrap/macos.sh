#!/usr/bin/env bash

set -euo pipefail

################################################################################
# Config before
################################################################################

if ! sudo grep -q "^$USER ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
	builtin echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo
fi

################################################################################
# CLI
################################################################################

TAPS=(
	domt4/autoupdate
	owasp-amass/amass
)
for tap in "${TAPS[@]}"; do
	brew tap "$tap"
done

CLI_APPS=(
	aircrack-ng
	amass
	aria2
	bash
	bash-completion@2
	bat
	bind
	binwalk
	blueutil
	brightness
	cabextract
	cliclick
	cmake
	composer
	coreutils
	crunch
	curl
	datamash
	diffutils
	dnsperf
	dos2unix
	e2fsprogs
	ettercap
	exiftool
	expect
	fd
	ffmpeg
	ffms2
	findomain
	findutils
	flac
	fzf
	gawk
	gcc
	gdrive
	git
	git-extras
	gnu-sed
	gnu-tar
	gnumeric
	go
	handbrake
	hivemq/mqtt-cli/mqtt-cli
	htmlq
	htop
	hydra
	icoutils
	iftop
	imagemagick
	img2pdf
	innoextract
	iodine
	iperf3
	ipinfo-cli
	insta360-link-controller
	java
	john-jumbo
	jq
	launchctl-completion
	lynis
	mariadb
	mas
	media-info
	midicsv
	miller
	MisterTea/et/et
	mitmproxy
	mkvtoolnix
	mpv
	mtr
	mvtools
	ncdu
	nethogs
	netmask
	newt
	ngrep
	nmap
	node
	oath-toolkit
	open-completion
	openssh
	opus-tools
	p7zip
	pandoc
	parallel
	pdfgrep
	pdftk-java
	php
	pip-completion
	pipx
	pnpm
	poppler
	pv
	pwgen
	pyenv
	python
	qrencode
	rclone
	rename
	restic
	ripgrep
	rustup
	shellcheck
	shfmt
	socat
	sox
	speedtest-cli
	sponge
	subliminal
	supervisor
	switchaudio-osx
	tcpdump
	telnet
	terminal-notifier
	tesseract
	thefuck
	tmux
	tor
	torsocks
	translate-shell
	trash
	tree
	u-boot-tools
	uni
	util-linux
	vapoursynth
	vim
	wakeonlan
	watch
	wget
	whois
	winetricks
	xq
	xz
	ykman
	yq
	yt-dlp
	zbar
	zsh
	zsh-completions
)
brew install "${CLI_APPS[@]}"

################################################################################
# GUI
################################################################################

GUI_APPS=(
	1password
	1password-cli
	adobe-creative-cloud
	alfred
	android-platform-tools
	appcleaner
	audio-hijack
	balenaetcher
	bartender
	bettertouchtool
	bit-slicer
	bricklink-studio
	burp-suite
	calibre
	charles
	chatgpt
	chrome-remote-desktop-host
	chromedriver
	cleanshot
	contexts
	copilot
	daisydisk
	discord
	docker
	dropbox
	elgato-control-center
	fabfilter-pro-c
	fabfilter-pro-q
	fabfilter-pro-r
	fantastical
	firefox
	garmin-basecamp
	garmin-express
	google-chrome
	google-cloud-sdk
	guitar-pro
	handbrake
	ilok-license-manager
	imaging-edge
	inkscape
	istat-menus
	iterm2
	izotope-product-portal
	keycastr
	loopback
	messenger
	meta
	metasploit
	monodraw
	native-access
	notion
	obs
	pixelsnap
	qlvideo
	rar
	rectangle-pro
	signal
	soundsource
	spitfire-audio
	spotify
	steam
	synthesia
	tailscale
	telegram
	textual
	the-unarchiver
	tor-browser
	visual-studio-code
	vlc
	waves-central
	whatsapp
	whisky
	wifi-explorer-pro
	wifispoof
	wireshark
	yacreader
	yubico-authenticator
	yubico-yubikey-manager
	zoom
)
brew install --cask "${GUI_APPS[@]}"

APP_STORE_APPS="$(command awk '{print $1}' <<<"
    1365531024      # 1Blocker
    1569813296      # 1Password for Safari
    937984704       # Amphetamine
    996933579       # AirTurn Manager
    1511935951      # BetterJSON
    424390742       # Compressor
    424389933       # Final Cut Pro
    363738376       # forScore
    1444383602      # Goodnotes
    1481302432      # Instapaper Save
    409035833       # iReal Pro
    409183694       # Keynote
    302584613       # Kindle
    634148309       # Logic Pro
    634159523       # MainStage
    1274495053      # Microsoft To Do
    434290957       # Motion
    409203825       # Numbers
    1451552749      # Open In Webmail
    409201541       # Pages
    639968404       # Parcel
    1529448980      # Reeder
    6471380298      # StopTheMadness Pro
    1482490089      # Tampermonkey
    497799835       # Xcode
")"
# shellcheck disable=SC2086
mas install $APP_STORE_APPS

################################################################################
# Languages
################################################################################

for lang in golang node python rust; do
	command bash "$(command dirname "$0")/lib/$lang.sh"
done

################################################################################
# Config after
################################################################################

# Homebrew
if ! command brew autoupdate status 2>/dev/null | command grep -q 'installed and running'; then
	command mkdir -p ~/Library/LaunchAgents && command brew autoupdate start --upgrade
fi
# Tor
command brew services start tor
