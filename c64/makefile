all: math.prg mandelbrot.prg

math.prg: math.a 
	ACME=ACME_LIB acme math.a 

mandelbrot.prg: mandelbrot.a
	ACME=ACME_LIB acme mandelbrot.a 

run: math.prg
	# x64sc --silent -warp math.prg 
	x64sc --silent math.prg 