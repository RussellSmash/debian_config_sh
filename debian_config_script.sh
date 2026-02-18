#!/bin/bash
## Script Universal de Configuração Debian GNU/Linux ##

## Variáveis Úteis ##
export PACKAGES_APT_DESKTOP="default-jdk plasma-workspace-wallpapers qsynth qjackctl flatpak pavucontrol timeshift fastfetch git"
export PACKAGES_FLATHUB_DESKTOP="org.telegram.desktop net.supertuxkart.SuperTuxKart org.xonotic.Xonotic io.github.ec_.Quake3e.OpenArena com.discordapp.Discord com.spotify.Client io.lmms.LMMS org.audacityteam.Audacity org.onlyoffice.desktopeditors com.heroicgameslauncher.hgl org.chromium.Chromium net.lutris.Lutris com.obsproject.Studio com.gopeed.Gopeed com.github.tchx84.Flatseal com.visualstudio.code com.valvesoftware.Steam "

echo "=========================================="
echo "Debian GNU/Linux KDE config by @joaov_7z"
echo "=========================================="

## Preparação ##

echo "incluindo repo non-free e backports..."

sudo sed -i 's/main$/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
sudo sed -i 's/main $/main contrib non-free non-free-firmware /g' /etc/apt/sources.list

CURRENT_URL=$(grep "^deb " /etc/apt/sources.list | grep "trixie" | head -n 1 | awk '{print $2}')

if [ -z "$CURRENT_URL" ]; then
    CURRENT_URL=$(grep -r "^deb " /etc/apt/sources.list.d/ | grep "trixie" | head -n 1 | awk '{print $3}')
fi

echo "Repositório atual detectado: $CURRENT_URL"

if [ ! -z "$CURRENT_URL" ]; then
    sudo tee /etc/apt/sources.list.d/trixie-backports.list > /dev/null <<EOF
# Gerado automaticamente via script - Backports baseado no mirror atual
deb $CURRENT_URL trixie-backports main contrib non-free non-free-firmware
deb-src $CURRENT_URL trixie-backports main contrib non-free non-free-firmware
EOF
    echo "Backports adicionado com sucesso!"
else
    echo "Erro: Não foi possível detectar a URL do repositório Trixie."
    exit 1
fi

echo "Atualizando Cache & Sistema..."

sudo apt update -y && sudo apt upgrade -y

echo "instalando e configurando ZRAM..."

sudo apt install -y systemd-zram-generator

sudo tee /etc/systemd/zram-generator.conf > /dev/null <<EOF
[zram0]
zram-size = min(16384, min(ram, 3072) + max(ram / 4, 512))
compression-algorithm = zstd
swap-priority = 100

[zram1]
zram-size = min(16384, min(ram, 3072) + max(ram / 4, 512))
compression-algorithm = zstd
swap-priority = 100
EOF

sudo tee /etc/sysctl.d/99-memory.conf > /dev/null <<EOF
# Memory and network tweaks of myghi63, best suited to use with zram, gaming and productivity scenarios.
# Author: Myghi63

# Disable read-ahead of swap pages (which massively slows ZRAM performance if enabled).
vm.page-cluster=0

# This feature can hurt performance too much at high memory pressure scenarios.
# Some distros like Ubuntu and custom kernels such as linux-zen already disables this.
vm.watermark_boost_factor=0

# Avoids nmap failures. This is essential for games with Proton.
vm.max_map_count=2147483642

# Enforce these vanilla kernel values to deal with custom kernels
vm.swappiness=60
vm.dirty_ratio=20
vm.dirty_background_ratio=10
vm.vfs_cache_pressure=100
vm.watermark_scale_factor=10
EOF

echo "recarregando daemon do sistema..."

sudo sysctl -p
sudo systemctl daemon-reload
sudo systemctl start /dev/zram0
sudo systemctl start /dev/zram1

echo "Instalando e Configurando Drivers Nvidia..."

sudo apt install -y linux-headers-$(uname -r) nvidia-driver nvidia-kernel-dkms

echo "Configurando UFW..."

sudo apt install -y ufw && sudo ufw enable && sudo ufw allow 1714:1764/udp && sudo ufw allow 1714:1764/tcp && sudo ufw reload

echo "Instalando Flatpak"

sudo apt install -y flatpak

echo "Configurando CUPS e EPSON L4260..."

sudo apt install -y system-config-printer printer-driver-escpr

sudo systemctl enable --now cups

echo "Configurando Flathub..."

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Instalando Pacotes $PACKAGES_APT_DESKTOP..."

sudo apt install -y $PACKAGES_APT_DESKTOP

echo "Instalando Pacotes $PACKAGES_FLATHUB_DESKTOP"

flatpak install --user -y $PACKAGES_FLATHUB_DESKTOP