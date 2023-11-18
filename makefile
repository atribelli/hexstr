# makefile

uname := $(shell uname)

stdcpp = c++17
stdc   = c17
optcpp = -O3
optc   = -O3

ifeq ($(uname), Linux)
optas  = --defsym IsLinux=1
else
optas  =
endif

# General C / C++ code and intrinsics

all: hexstr-c hexstr-intrin

hexstr-c: main.o hexstr-c.o
	g++ -o hexstr-c -std=$(stdcpp) $(optcpp) main.o hexstr-c.o

hexstr-c.o: hexstr.h hexstr.c
	gcc -o hexstr-c.o -c -std=$(stdc) $(optc) hexstr.c

hexstr-intrin: main.o hexstr-intrin.o
	g++ -o hexstr-intrin -std=$(stdcpp) $(optcpp) main.o hexstr-intrin.o

hexstr-intrin.o: hexstr.h hexstr.c
	gcc -o hexstr-intrin.o -c -std=$(stdc) $(optc) -DUSE_SIMD hexstr.c

main.o: hexstr.h main.cpp
	g++ -c -std=$(stdcpp) $(optcpp) main.cpp

# ARM assembly language code

arm: hexstr-a64 hexstr-neon

hexstr-a64: main.o hexstr-a64.o
	g++ -o hexstr-a64 -std=$(stdcpp) $(optcpp) main.o hexstr-a64.o

hexstr-a64.o: hexstr-a64.s
	as -o hexstr-a64.o $(optas) hexstr-a64.s

hexstr-neon: main.o hexstr-neon.o
	g++ -o hexstr-neon -std=$(stdcpp) $(optcpp) main.o hexstr-neon.o

hexstr-neon.o: hexstr-neon.s
	as -o hexstr-neon.o $(optas) hexstr-neon.s

# Intel assembly language code

intel: hexstr-x64 hexstr-sse hexstr-avx

hexstr-x64: main.o hexstr-x64.o
	g++ -o hexstr-x64 -std=$(stdcpp) $(optcpp) main.o hexstr-x64.o

hexstr-x64.o: hexstr-x64.s
	as -o hexstr-x64.o $(optas) hexstr-x64.s

hexstr-sse: main.o hexstr-sse.o
	g++ -o hexstr-sse -std=$(stdcpp) $(optcpp) main.o hexstr-sse.o

hexstr-sse.o: hexstr-sse.s
	as -o hexstr-sse.o $(optas) hexstr-sse.s

hexstr-avx: main.o hexstr-avx.o
	g++ -o hexstr-avx -std=$(stdcpp) $(optcpp) main.o hexstr-avx.o

hexstr-avx.o: hexstr-avx.s
	as -o hexstr-avx.o $(optas) hexstr-avx.s

# Quietly clean up

clean:
	rm -f hexstr-c hexstr-intrin hexstr-a64 hexstr-neon hexstr-x64 hexstr-sse hexstr-avx a.out *.o
