#!/bin/bash

qemu-system-aarch64 \
    -M virt -m 1024 -cpu cortex-a57 \
    -kernel Image \
    -initrd initramfs-linux.img \
    -no-reboot \
    -nographic \
    -serial mon:stdio \
    -drive file=raw.img,format=raw,if=virtio \
    -append "root=/dev/vda2 rw console=ttyAMA0"
