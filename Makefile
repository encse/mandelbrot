all: boot.img

boot.bin:  src/main.asm
	@echo '                                                  '
	@echo '                                ▄█▌               '
	@echo '                               ╫████              '
	@echo '                             ┌ ,███▌              '
	@echo '                       ██▄▄█████████████▄▄ ▄▄     '
	@echo '                      ┌▄████████████████████▀     '
	@echo '                     ████████████████████████     '
	@echo '                   ,██████████████████████████▀   '
	@echo '        ██████▄▄   ███████████████████████████W   '
	@echo '    . ███████████ ╫███████████████████████████¬   '
	@echo '   ▄▄▄████████████╫█████████████████████████▀     '
	@echo '   ▀▀▀███████████████████████████████████████     '
	@echo '      ╠██████████ ╟███████████████████████████    '
	@echo '        █▀████▀▀   ███████████████████████████M   '
	@echo '                   `██████████████████████████▄   '
	@echo '                     ████████████████████████     '
	@echo '                      ╙▀████████████████████▄     '
	@echo '                       ██▀▀█████████████▀▀ ▀▀     '
	@echo '                             └ `███▌              '
	@echo '                               ╫████              '
	@echo '                                ╙█▌               '
	@echo '                                                  '
	@echo ''
	@echo "\033[32mCreating boot.bin....\033[39;49m"
	nasm -i src -fbin -o bin/boot.bin src/main.asm 

boot.img: boot.bin
	@echo ''
	@echo "\033[32mCreating floppy image....\033[39;49m"
	dd if=/dev/zero of=bin/boot.img bs=1024 count=1440 && dd if=bin/boot.bin of=bin/boot.img conv=notrunc 
	cp bin/boot.img site
	
run: all
	@echo ''
	@echo "\033[32mStarting up Qemu.... Ctrl+C to exit\033[39;49m"
	qemu-system-x86_64 -accel hvf -drive format=raw,file=bin/boot.bin

generate-palette:
	@echo ''
	@echo "\033[32mGenerating palette....\033[39;49m"
	node src/generate-palette.js