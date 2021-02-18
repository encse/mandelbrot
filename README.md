# Mandelbrot drawers for vintage hardware

A collection of Mandelbrot drawers for old hardware. I use this repo to learn about ancient stuff, and improve assembly skills.


![screenshot](site/screenshot.png)

Live demo available [here](https://csokavar.hu/projects/mandelbrot).

## For the x86 version
I used `Qemu` and `Nasm` on my mac for development:

```
    brew install qemu
    brew install nasm
```

To build and run:
```
    make run-x86
```

## For the C64 version

I used the `vice` emulator and the `acme` assembler.

```
    brew install vice
    brew install acme
```

To build and run:
```
    make run-c64
```

