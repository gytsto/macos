#!/usr/bin/env bash
set -Eeuo pipefail

: "${APP:="macOS"}"
: "${VGA:="vmware"}"
: "${DISK_TYPE:="blk"}"
: "${PLATFORM:="x64"}"
: "${SUPPORT:="https://github.com/dockur/macos"}"

cd /run

. utils.sh # Load functions
. reset.sh # Initialize system

if [ -d "/storage" ] && [ "$(ls -A /storage)" ]; then
    if [[ "${COMMIT:-}" == [Yy1]* ]]; then
        cp -R /storage/* /local
    fi
fi

. install.sh # Get the OSX images
. disk.sh    # Initialize disks
. display.sh # Initialize graphics
. network.sh # Initialize network
. boot.sh    # Configure boot
. proc.sh    # Initialize processor
. config.sh  # Configure arguments

trap - ERR

version=$(qemu-system-x86_64 --version | head -n 1 | cut -d '(' -f 1 | awk '{ print $NF }')
info "Booting ${APP}${BOOT_DESC} using QEMU v$version..."

exec qemu-system-x86_64 ${ARGS:+ $ARGS} &
term_pd=$!

sleep 30

if [[ -n "${EXTRA_SCRIPT:-}" ]]; then
    info "Executing extra script: $EXTRA_SCRIPT"
    if ! "$EXTRA_SCRIPT"; then
        error "Extra script failed"
        exit 555
    fi
fi

info "Macos started successfully, you can now connect using RDP or visit http://localhost:8006/ to view the screen..."
touch "/ready"

wait $term_pd || :

rm "/ready"
