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
	make -C src/c64 all

	@echo ''
	@echo "\033[32m====== Building x86 target ======\033[39;49m"
	make -C src/x86 all

	@echo ''
	@echo "\033[32m====== Building the site ======\033[39;49m"
	
	mkdir -p docs/bin
	mv src/x86/*.img docs/bin
	mv src/x86/*.bin docs/bin

	mv src/c64/*.prg docs/bin
	mv src/c64/*.d64 docs/bin

	npm run build --prefix src/site

run-c64:
	make -C src/c64 run

run-x86:
	make -C src/x86 run

run-site: all
	open http://localhost:8000 &
	python3 -m http.server --directory docs
