all:
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
	@echo "\033[32m====== Building C64 target ======\033[39;49m"
	make -C c64 all

	@echo ''
	@echo "\033[32m====== Building x86 target ======\033[39;49m"
	make -C x86 all

	make make-site

make-site:
	@echo ''
	@echo "\033[32m====== Building the site ======\033[39;49m"
	cp bin/boot.img site/dist
	cp bin/mandelbrot.d64 site/dist
	npm run build --prefix site

run-c64:
	make -C c64 run

run-x86:
	make -C x86 run

