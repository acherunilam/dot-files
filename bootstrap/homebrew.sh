#!/usr/bin/env bash
# shellcheck disable=SC2086


# Load third-party repositories.
taps="$(command sed '/^#/d' <<< "
caffix/amass
denji/nginx
homebrew/autoupdate
eddieantonio/eddieantonio
")"
brew tap $taps


# Install CLI apps.
apps="$(command sed '/^#/d' <<< "
aircrack-ng
amass
aria2
bash
bash-completion@2
bind
blueutil
brew-cask-completion
brightness
cabextract
cliclick
cmake
colordiff
coreutils
curl
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
iftop
imagemagick
imgcat
innoextract
iperf3
john-jumbo
jq
launchctl-completion
lesspipe
mas
media-info
miller
mkvtoolnix
mpv
mtr
ncdu
nethogs
nginx-full --with-fancyindex-module --with-http2 --with-autols-module
ngrep
nmap
node
oath-toolkit
open-completion
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
screen
shellcheck
shfmt
sipcalc
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
zsh
zsh-completions
")"
brew install $apps


# Install GUI apps.
casks="$(command sed '/^#/d' <<< "
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
miniconda
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
sublime-text
synthesia
textual
the-unarchiver
tuntap
tuxera-ntfs
vlc
whatsapp
wifi-explorer
wireshark
xee
yacreader
zenmap
zoomus
")"
brew install --cask $casks
