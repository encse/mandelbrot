# Mandelbrot set as a bootloader

A 16 bit bootloader written in assembly, featuring 320x200 graphics with 256 colors and mouse handling. 

![screenshot](screenshot.png)

Setup requirements on (mac)
```
    brew install qemu
    brew install nasm
```

To build and run:
```
    make run
```

The makefile creates a bootable `.img` floppy image as well that can be used in VirtualBox or possibly on a physical machine.