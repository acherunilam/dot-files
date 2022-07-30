#!/usr/bin/env bash


# Load third-party repositories.
TAPS=(
    caffix/amass
    denji/nginx
    homebrew/autoupdate
    homebrew/cask-drivers
)
brew tap "${TAPS[@]}"


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
    burp-suite
    cabextract
    cliclick
    cmake
    coreutils
    crunch
    curl
    diffutils
    dnsperf
    docker-completion
    docker-compose-completion
    e2fsprogs
    ettercap
    exiftool
    expect
    fasd
    fd
    ffmpeg
    findutils
    flac
    fzf
    gawk
    gcc
    gdrive
    geoip
    geoipupdate
    git
    git-extras
    gnu-sed
    go
    handbrake
    hping
    htop
    hydra
    iftop
    imagemagick
    innoextract
    iperf3
    john-jumbo
    jq
    launchctl-completion
    lynis
    mas
    media-info
    miller
    mkvtoolnix
    mpv
    mtr
    ncdu
    netmask
    nethogs
    nginx-full --with-fancyindex-module --with-http2 --with-autols-module
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
    pip-completion
    poppler
    pv
    python
    qrencode
    rename
    restic
    ripgrep
    rustup-init
    secretive
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
    010-editor
    1password
    1password-cli
    alfred
    android-platform-tools
    appcleaner
    audio-hijack
    balenaetcher
    bettertouchtool
    bit-slicer
    bricklink-studio
    calibre
    charles
    chrome-remote-desktop-host
    chromedriver
    contexts
    daisydisk
    discord
    docker
    dosbox
    dropbox
    fantastical
    firefox
    google-chrome
    handbrake
    intel-power-gadget
    istat-menus
    iterm2
    java
    keepingyouawake
    kindle
    knockknock
    little-snitch
    loopback
    meta
    metasploit
    notion
    obs
    obs-virtualcam
    playonmac
    qlvideo
    rar
    rectangle
    signal
    spotify
    steam
    synthesia
    textual
    the-unarchiver
    tuxera-ntfs
    vlc
    whatsapp
    wifi-explorer-pro
    wireshark
    xee
    yacreader
    yubico-authenticator
    yubico-yubikey-manager
    zenmap
    zoomus
)
brew install --cask "${GUI_APPS[@]}"
