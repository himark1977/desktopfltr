# desktopenv_fltr

A new Flutter project.

## Getting Started

flutter clean
flutter pub get

flutter run -d linux

sudo apt install xorg xserver-xorg xinit
sudo apt update
sudo apt install git curl unzip build-essential clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor

flutter config --enable-linux-desktop

flutter build linux

touch ~/.xinitrc
#!/bin/sh
exec /home/USERNAME/desktopfltr/build/linux/arm64/release/bundle/desktopenv_fltr

startx

