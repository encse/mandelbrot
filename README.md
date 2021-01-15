# Bootloader

This is a trivial bootloader written in assembly.

![screenshot](screenshot.png)

Setup requirements (mac)
```
brew install qemu
brew install nasm
```

Build and run:
```
nasm bootloader.asm -o bootloader.bin && qemu-system-i386 -drive format=raw,file=bootloader.bin
```
