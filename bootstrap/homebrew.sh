#!/usr/bin/env bash


# Load third-party repositories.
TAPS=(
    caffix/amass
    denji/nginx
    homebrew/autoupdate
    homebrew/cask-drivers
)
for tap in "${TAPS[@]}" ; do
    brew tap "$tap"
done


# Install CLI apps.
CLI_APPS=(
    aircrack-ng
    amass
    aria2
    bash
    bash-completion@2
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
    findutils
    flac
    fzf
    gawk
    gcc
    gcc-c++
    gdrive
    geoip
    geoipupdate
    git
    git-extras
    gnu-sed
    gnu-tar
    go
    handbrake
    hping
    htmlq
    htop
    hydra
    iftop
    imagemagick
    innoextract
    iodine
    iperf3
    john-jumbo
    jq
    launchctl-completion
    lynis
    mariadb
    mas
    media-info
    miller
    MisterTea/et/et
    mkvtoolnix
    mpv
    mtr
    mvtools
    ncdu
    nethogs
    netmask
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
    pdftk-java
    php
    pip-completion
    pnpm
    poppler
    pv
    python
    qrencode
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
    trash
    tree
    tvnamer
    util-linux
    vapoursynth
    vim
    wakeonlan
    watch
    wget
    whois
    wifi-password
    winetricks
    xz
    youtube-dl
    yq
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
    bettertouchtool
    bit-slicer
    bricklink-studio
    burp-suite
    calibre
    charles
    chrome-remote-desktop-host
    chromedriver
    contexts
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
    istat-menus
    iterm2
    keepingyouawake
    kindle
    knockknock
    little-snitch
    loopback
    messenger
    meta
    metasploit
    monodraw
    notion
    obs
    obs-virtualcam
    pixelsnap
    qlvideo
    rar
    rectangle
    roli-connect
    secretive
    spotify
    steam
    synthesia
    telegram
    textual
    the-unarchiver
    tor-browser
    tuxera-ntfs
    visual-studio-code
    vlc
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
