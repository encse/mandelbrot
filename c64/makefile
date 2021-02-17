all: mandelbrot.prg

mandelbrot.prg: mandelbrot.a fixedpoint.a
	ACME=ACME_LIB acme mandelbrot.a 

run: mandelbrot.prg
	x64sc --silent -warp  -iecdevice4 -device4 1 -pr4drv ascii -pr4output text -pr4txtdev 0 -prtxtdev1 test_output mandelbrot.prg 
	