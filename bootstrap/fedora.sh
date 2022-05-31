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
for repo in free nonfree ; do
    sudo dnf install -y "https://mirrors.rpmfusion.org/$repo/fedora/rpmfusion-$repo-release-$(rpm -E %fedora).noarch.rpm"
done
sudo dnf upgrade -y


# Install CLI apps.
CLI_APPS=(
    aircrack-ng
    aria2
    bcc-tools
    calibre
    cargo
    cmake
    colordiff
    dnsperf
    et
    ettercap
    expect
    fd-find
    ffmpeg
    fzf
    GeoIP
    geoipupdate
    git-extras
    golang
    hping3
    htop
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
    nethogs
    netmask
    ngrep
    nmap
    nodejs
    oathtool
    p7zip
    parallel
    poppler
    prename
    pv
    python3-pip
    qrencode
    ripgrep
    rust
    ShellCheck
    shfmt
    socat
    speedtest-cli
    telnet
    thefuck
    tor
    unrar
    vim
    wireguard-tools
    wireshark-cli
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
