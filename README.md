# Mandelbrot set as a bootloader

A 16 bit bootloader written in assembly, featuring 320x200 graphics with 256 colors and mouse handling. 

![screenshot](screenshot.png)

For developement I used Qemu and Nasm on my mac:

```
    brew install qemu
    brew install nasm
```

To build and run:
```
    make run
```

The makefile creates a bootable floppy image [.img](bin/boot.img) as well. This can be used in VirtualBox 
or possibly on a physical machine.