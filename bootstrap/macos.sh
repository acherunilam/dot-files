#!/usr/bin/env bash

################################################################################
# CLI
################################################################################

TAPS=(
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
	e2fsprogs
	ettercap
	exiftool
	expect
	fasd
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
	hping
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
	java
	john-jumbo
	jq
	launchctl-completion
	lynis
	mariadb
	mas
	media-info
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
	pnpm
	poppler
	pv
	pwgen
	python
	qrencode
	rclone
	rename
	restic
	ripgrep
	rustup-init
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
	uni
	util-linux
	vapoursynth
	vim
	wakeonlan
	watch
	wget
	whois
	wifi-password
	winetricks
	xq
	xz
	ykman
	youtube-dl
	yq
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
	fantastical
	firefox
	garmin-basecamp
	garmin-express
	google-chrome
	google-cloud-sdk
	guitar-pro
	handbrake
	inkscape
	istat-menus
	iterm2
	keycastr
	kindle
	knockknock
	little-snitch
	logitech-g-hub
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
	roli-connect
	secretive
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
	tuxera-ntfs
	u-boot-tools
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
