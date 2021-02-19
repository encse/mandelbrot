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
	
	cp x86/*.img site/dist/bin
	cp x86/*.bin site/dist/bin

	cp c64/*.prg site/dist/bin
	cp c64/*.d64 site/dist/bin

	npm run build --prefix site


run-c64:
	make -C c64 run

run-x86:
	make -C x86 run

run-site: make-site
	open http://localhost:8000 &
	python3 -m http.server --directory site/dist

