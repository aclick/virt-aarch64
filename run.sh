#!/bin/bash

qemu-system-aarch64 \
    -M virt -m 1024 -cpu cortex-a57 \
    -kernel ArchLinuxARM-rpi-aarch64-latest/boot/Image \
    -initrd ArchLinuxARM-rpi-aarch64-latest/boot/initramfs-linux.img \
    -no-reboot \
    -serial stdio \
    -drive file=archpi.img,if=virtio \
    -append "root=/dev/vda rw console=ttyAMA0"
