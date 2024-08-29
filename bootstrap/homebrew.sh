#!/usr/bin/env bash

# Load third-party repositories.
TAPS=(
	owasp-amass/amass
	denji/nginx
	homebrew/autoupdate
	homebrew/cask-drivers
)
for tap in "${TAPS[@]}"; do
	brew tap "$tap"
done

# Install CLI apps.
CLI_APPS=(
	aircrack-ng
	amass
	aria2
	bash
	bash-completion@2
	bat
	bind
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
	nginx-full
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
	tvnamer
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

# Install GUI apps.
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
	visual-studio-code
	vlc
	waves-central
	whatsapp
	wifi-explorer-pro
	wifispoof
	wireshark
	yacreader
	yubico-authenticator
	yubico-yubikey-manager
	zoom
)
brew install --cask "${GUI_APPS[@]}"
