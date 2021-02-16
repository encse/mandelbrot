all: math.prg mandelbrot.prg

math.prg: math.a 16bit.a fixpoint.a
	ACME=ACME_LIB acme math.a 

mandelbrot.prg: mandelbrot.a 16bit.a fixpoint.a
	ACME=ACME_LIB acme mandelbrot.a 

run-math: math.prg
	# x64sc --silent -warp math.prg 
	x64sc --silent math.prg 

mathbas.prg: math.bas
	prg-tools/bas2prg <math.bas >mathbas.prg

run-math-bas: mathbas.prg
#	x64sc --silent -iecdevice4 -device4 1 -pr4drv mps803 -pr4output graphics -pr4txtdev 0 -prtxtdev1 test_output mathbas.prg 
	x64sc --silent -iecdevice4 -device4 1 -pr4drv ascii -pr4output text -pr4txtdev 0 -prtxtdev1 test_output mathbas.prg 

run: mandelbrot.prg
	x64sc --silent -warp  -iecdevice4 -device4 1 -pr4drv ascii -pr4output text -pr4txtdev 0 -prtxtdev1 test_output mandelbrot.prg 
	