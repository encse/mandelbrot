all: boot.img

boot.bin:  src/main.asm
	nasm -i src -fbin -o bin/boot.bin src/main.asm 

boot.img: boot.bin
	dd if=/dev/zero of=bin/boot.img bs=1024 count=1440 && dd if=bin/boot.bin of=bin/boot.img conv=notrunc 

run: boot.bin
	qemu-system-x86_64 -accel hvf -drive format=raw,file=bin/boot.bin

generate-palette:
	node src/generate-palette.js