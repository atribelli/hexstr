# makefile

uname   := $(shell uname)
longbit := $(shell getconf LONG_BIT)

optcpp = -std=c++17 -O3
optc   = -std=c17 -O3
#optdb  = -g

ifeq ($(uname), Linux)  # Linux assembly needs GNU specific section
optas  = --defsym IsLinux=1
else
optas  =
endif

ifeq ($(longbit), 32)   # ARM-v7a is the only supported 32-bit platform
optneon = -march=armv7-a -mfpu=neon-vfpv3
else
optneon =
endif

# General C / C++ code and intrinsics

all: hexstr-c hexstr-intrin

hexstr-c: main.o hexstr-c.o
	g++ $(optdb) -o hexstr-c $(optcpp) main.o hexstr-c.o

main.o: hexstr.h main.cpp
	g++ $(optdb) -c $(optcpp) main.cpp

hexstr-c.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-c.o -c $(optc) hexstr.c

hexstr-intrin: main.o hexstr-intrin.o
	g++ $(optdb) -o hexstr-intrin $(optcpp) main.o hexstr-intrin.o

hexstr-intrin.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-intrin.o -c $(optc) $(optneon) -DUSE_SIMD hexstr.c

# ARM assembly language code

arm64: hexstr-a64 hexstr-neon64

hexstr-a64: main.o hexstr-a64.o
	g++ $(optdb) -o hexstr-a64 $(optcpp) main.o hexstr-a64.o

hexstr-a64.o: hexstr-a64.s
	as $(optdb) -o hexstr-a64.o $(optas) hexstr-a64.s

hexstr-neon64: main.o hexstr-neon64.o
	g++ $(optdb) -o hexstr-neon64 $(optcpp) main.o hexstr-neon64.o

hexstr-neon64.o: hexstr-neon64.s
	as $(optdb) -o hexstr-neon64.o $(optas) hexstr-neon64.s

arm32: hexstr-a32 hexstr-neon32 hexstr-thumb

hexstr-a32: main.o hexstr-a32.o
	g++ $(optdb) -o hexstr-a32 $(optcpp) main.o hexstr-a32.o

hexstr-a32.o: hexstr-a32.s
	as $(optdb) -o hexstr-a32.o $(optas) hexstr-a32.s

hexstr-neon32: main.o hexstr-neon32.o
	g++ $(optdb) -o hexstr-neon32 $(optcpp) main.o hexstr-neon32.o

hexstr-neon32.o: hexstr-neon32.s
	as $(optdb) -o hexstr-neon32.o $(optas) hexstr-neon32.s

hexstr-thumb: main.o hexstr-thumb.o
	g++ $(optdb) -o hexstr-thumb $(optcpp) main.o hexstr-thumb.o

hexstr-thumb.o: hexstr-thumb.s
	as $(optdb) -o hexstr-thumb.o $(optas) hexstr-thumb.s

# Intel assembly language code

intel: hexstr-x64 hexstr-sse hexstr-avx

hexstr-x64: main.o hexstr-x64.o
	g++ $(optdb) -o hexstr-x64 $(optcpp) main.o hexstr-x64.o

hexstr-x64.o: hexstr-x64.s
	as $(optdb) -o hexstr-x64.o $(optas) hexstr-x64.s

hexstr-sse: main.o hexstr-sse.o
	g++ $(optdb) -o hexstr-sse $(optcpp) main.o hexstr-sse.o

hexstr-sse.o: hexstr-sse.s
	as $(optdb) -o hexstr-sse.o $(optas) hexstr-sse.s

hexstr-avx: main.o hexstr-avx.o
	g++ $(optdb) -o hexstr-avx $(optcpp) main.o hexstr-avx.o

hexstr-avx.o: hexstr-avx.s
	as $(optdb) -o hexstr-avx.o $(optas) hexstr-avx.s

# Quietly clean up

clean:
	rm -f hexstr-c hexstr-intrin hexstr-a64 hexstr-neon64 hexstr-a32 hexstr-neon32 hexstr-thumb hexstr-x64 hexstr-sse hexstr-avx a.out *.o
