#!/bin/bash
set -e

DISTRO=${1:-debian}
TARBALL="dist/nvim-offline.tar.gz"

if [ ! -f "$TARBALL" ]; then
    echo "Error: $TARBALL not found. Run 'make dist' first."
    exit 1
fi

case "$DISTRO" in
    debian)
        IMAGE="debian:latest"
        PKG_INSTALL="apt-get update && apt-get install -y make"
        ;;
    arch)
        IMAGE="archlinux:latest"
        PKG_INSTALL="pacman -Sy --noconfirm make"
        ;;
    fedora)
        IMAGE="fedora:latest"
        PKG_INSTALL="dnf install -y make"
        ;;
    *)
        echo "Unknown distro: $DISTRO. Use: debian, arch, fedora"
        exit 1
        ;;
esac

echo "Spinning up $DISTRO container..."

docker run -it --rm \
    -v "$(pwd)/$TARBALL:/tmp/nvim-offline.tar.gz:ro" \
    "$IMAGE" \
    bash -c "
        $PKG_INSTALL
        mkdir -p /opt/nvim-offline
        tar -xzf /tmp/nvim-offline.tar.gz -C /opt/nvim-offline
        cd /opt/nvim-offline
        make install
        exec bash
    "
