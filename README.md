# Mandelbrot set as a bootloader

A 16 bit bootloader written in assembly, featuring 320x200 graphics with 256 colors and mouse handling. 

![screenshot](site/screenshot.png)

Live demo available [here](https://csokavar.hu/projects/mandelbrot).

I used Qemu and Nasm on my mac for development:

```
    brew install qemu
    brew install nasm
```

To build and run:
```
    make run
```

The makefile creates a bootable [floppy image](bin/boot.img) as well. This can be used in VirtualBox 
or on real hardware:

![screenshot](site/p3.jpg | width=320)

