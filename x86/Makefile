all: boot.img

boot.bin:  main.asm
	@echo ''
	@echo "\033[32mCreating boot.bin....\033[39;49m"
	nasm -fbin -o boot.bin main.asm 

boot.img: boot.bin
	@echo ''
	@echo "\033[32mCreating floppy image....\033[39;49m"
	dd if=/dev/zero of=boot.img bs=1024 count=1440 && dd if=boot.bin of=boot.img conv=notrunc 
	
run: all
	@echo ''
	@echo "\033[32mStarting up Qemu.... Ctrl+C to exit\033[39;49m"
	qemu-system-x86_64 -accel hvf -drive format=raw,file=boot.bin

generate-palette:
	@echo ''
	@echo "\033[32mGenerating palette....\033[39;49m"
	node generate-palette.js