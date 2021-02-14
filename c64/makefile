all: math.prg mandelbrot.prg

math.prg: math.a 16bit.a fixpoint.a
	ACME=ACME_LIB acme math.a 

mandelbrot.prg: mandelbrot.a 16bit.a fixpoint.a
	ACME=ACME_LIB acme mandelbrot.a 

run-math: math.prg
	# x64sc --silent -warp math.prg 
	x64sc --silent math.prg 

run: mandelbrot.prg
	x64sc --silent -warp mandelbrot.prg 
	