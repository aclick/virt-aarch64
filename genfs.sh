#!/bin/bash

set -ueo pipefail

function assert_dne {
    [[ -e $1 ]] && { echo >&2 "$1 already exists."; return  1; }
    return 0
}

function assert_block {
    if [[ -b "$1" ]]; then
        echo "$1 ok"
        return 0
    fi
    echo "$1 not a block special device"
    return 1
}

function assert_dir {
    if [[ -d "$1" ]]; then
        echo "$1 ok"
        return 0
    fi
    echo "$1 not a directory"
    return 1
}

function assert_fs {
    if [[ "$(sudo blkid $1 | sed 's/.*TYPE=\"\([^"]*\)\".*/\1/')" = "$2" ]]; then
        echo "$1 is a $2 filesystem"
        return 0
    fi
    echo "$1 is not a $2 filesystem: $(sudo blkid $1)"
    return 1
}

declare -a cleanup_items
function cleanup {
    #append
    #cleanup_items+=("$*")

    #prepend
    cleanup_items=("$*" "${cleanup_items[@]}")
}

function on_exit {
    bash --rcfile <(echo "PS1='[pre-cleanup] $ '") -i
    declare -p cleanup_items
    for i in "${cleanup_items[@]}"
    do
        echo "on_exit: $i"
        eval $i
    done
    echo "Cleanup complete"
}
trap on_exit EXIT

assert_dne raw.img
dd if=/dev/zero of=raw.img bs=1M count=8000 status=progress
sfdisk raw.img < raw.sfdisk

lodev=$(sudo losetup -fP --show raw.img)
cleanup sudo losetup -d ${lodev}
loboot=${lodev}p1
loroot=${lodev}p2

assert_block ${lodev}
assert_block ${loboot}
assert_block ${loroot}

sudo mkfs.fat -F 32 ${loboot}
sudo mkfs.ext4 ${loroot}
sync

bootmnt=$(mktemp -d -p . boot.XXXX)
cleanup rmdir ${bootmnt}
rootmnt=$(mktemp -d -p . root.XXXX)
cleanup rmdir ${rootmnt}

assert_dir ${bootmnt}
assert_dir ${rootmnt}

assert_fs ${loboot} "vfat"
assert_fs ${loroot} "ext4"

sudo mount ${loboot} ${bootmnt}
cleanup sudo umount ${loboot}
sudo mount ${loroot} ${rootmnt}
cleanup sudo umount ${loroot}

[[ -e latest.tar.gz ]] || wget -O latest.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
#cleanup rm latest.tar.gz
sudo bsdtar -xpf latest.tar.gz -C ${rootmnt}
sync
sudo mv ${rootmnt}/boot/* ${bootmnt}/
echo "/dev/vda1  /boot  vfat  defaults,rw	 0 2" | sudo tee -a "${rootmnt}/etc/fstab"
echo "/dev/vda2  /      ext4  rw,relatime	 0 1" | sudo tee -a "${rootmnt}/etc/fstab"
cp ${bootmnt}/Image .
cp ${bootmnt}/initramfs-linux.img .

