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
optneon = -march=armv8-a
endif

optavx  = -march=haswell



#-----------------------------------------------------------------------------
# Intel x64 code

intel: cpuid hexstr-c hexstr-intrin hexstr-x64 hexstr-sse hexstr-avx decstr-c decstr-intrin decstr-x64 decstr-sse decstr-avx

cpuid: cpuinfo.o cpuid.o
	gcc $(optdb) -o cpuid $(optc) cpuinfo.o cpuid.o

cpuid.o: cpuinfo.h cpuid.c
	gcc $(optdb) -o cpuid.o -c $(optc) cpuid.c

cpuinfo.o: cpuinfo.h cpuinfo.c
	gcc $(optdb) -c $(optc) cpuinfo.c

hexstr-c: mainh.o cpuinfo.o hexstr-test.o hexstr-c.o
	g++ $(optdb) -o hexstr-c $(optcpp) $(optavx) mainh.o cpuinfo.o hexstr-test.o hexstr-c.o

hexstr-c.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-c.o -c $(optc) $(optavx) hexstr.c

hexstr-intrin: mainh.o cpuinfo.o hexstr-test.o hexstr-intrin.o
	g++ $(optdb) -o hexstr-intrin $(optcpp) $(optavx) mainh.o cpuinfo.o hexstr-test.o hexstr-intrin.o

hexstr-intrin.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-intrin.o -c $(optc) $(optavx) -DUSE_SIMD hexstr.c

hexstr-x64: mainh.o cpuinfo.o hexstr-test.o hexstr-x64.o
	g++ $(optdb) -o hexstr-x64 $(optcpp) $(optavx) mainh.o cpuinfo.o hexstr-test.o hexstr-x64.o

hexstr-x64.o: hexstr-x64.s
	as $(optdb) -o hexstr-x64.o $(optas) hexstr-x64.s

hexstr-sse: mainh.o cpuinfo.o hexstr-test.o hexstr-sse.o
	g++ $(optdb) -o hexstr-sse $(optcpp) $(optavx) mainh.o cpuinfo.o hexstr-test.o hexstr-sse.o

hexstr-sse.o: hexstr-sse.s
	as $(optdb) -o hexstr-sse.o $(optas) hexstr-sse.s

hexstr-avx: mainh.o cpuinfo.o hexstr-test.o hexstr-avx.o
	g++ $(optdb) -o hexstr-avx $(optcpp) $(optavx) mainh.o cpuinfo.o hexstr-test.o hexstr-avx.o

hexstr-avx.o: hexstr-avx.s
	as $(optdb) -o hexstr-avx.o $(optas) hexstr-avx.s

hexstr-test.o: hexstr.h hexstr-test.cpp
	g++ $(optdb) -c $(optcpp) $(optavx) -o hexstr-test.o hexstr-test.cpp

mainh.o: hexstr.h mainh.cpp
	g++ $(optdb) -c $(optcpp) $(optavx) mainh.cpp

decstr-c: maind.o cpuinfo.o decstr-test.o decstr-c.o
	g++ $(optdb) -o decstr-c $(optcpp) $(optavx) maind.o cpuinfo.o decstr-test.o decstr-c.o

decstr-c.o: decstr.h decstr.c
	gcc $(optdb) -o decstr-c.o -c $(optc) $(optavx) decstr.c

decstr-intrin: maind.o cpuinfo.o decstr-test.o decstr-intrin.o
	g++ $(optdb) -o decstr-intrin $(optcpp) $(optavx) maind.o cpuinfo.o decstr-test.o decstr-intrin.o

decstr-intrin.o: decstr.h decstr.c
	gcc $(optdb) -o decstr-intrin.o -c $(optc) $(optavx) -DUSE_SIMD decstr.c

decstr-x64: maind.o cpuinfo.o decstr-test.o decstr-x64.o
	g++ $(optdb) -o decstr-x64 $(optcpp) $(optavx) maind.o cpuinfo.o decstr-test.o decstr-x64.o

decstr-x64.o: nextdigits.s decstr-x64.s
	as $(optdb) -o decstr-x64.o $(optas) decstr-x64.s

decstr-sse: maind.o cpuinfo.o decstr-test.o decstr-sse.o
	g++ $(optdb) -o decstr-sse $(optcpp) $(optavx) maind.o cpuinfo.o decstr-test.o decstr-sse.o

decstr-sse.o: nextdigits.s decstr-sse.s
	as $(optdb) -o decstr-sse.o $(optas) decstr-sse.s

decstr-avx: maind.o cpuinfo.o decstr-test.o decstr-avx.o
	g++ $(optdb) -o decstr-avx $(optcpp) $(optavx) maind.o cpuinfo.o decstr-test.o decstr-avx.o

decstr-avx.o: nextdigits.s decstr-avx.s
	as $(optdb) -o decstr-avx.o $(optas) decstr-avx.s

decstr-test.o: decstr.h decstr-test.cpp
	g++ $(optdb) -c $(optcpp) $(optavx) -o decstr-test.o decstr-test.cpp

maind.o: decstr.h maind.cpp
	g++ $(optdb) -c $(optcpp) $(optavx) -o maind.o maind.cpp



#-----------------------------------------------------------------------------
# ARM64 code

arm64: hexstr-a64c hexstr-a64intrin hexstr-a64asm hexstr-neon64

hexstr-a64c: a64mainh.o a64cpuinfo.o a64hexstr-test.o hexstr-a64c.o
	g++ $(optdb) -o hexstr-a64c $(optcpp) $(optneon) a64mainh.o a64cpuinfo.o a64hexstr-test.o hexstr-a64c.o

a64mainh.o: hexstr.h mainh.cpp
	g++ $(optdb) -o a64mainh.o -c $(optcpp) $(optneon) mainh.cpp

a64cpuinfo.o: cpuinfo.h cpuinfo.c
	g++ $(optdb) -o a64cpuinfo.o -c $(optcpp) $(optneon) cpuinfo.c

a64hexstr-test.o: hexstr.h hexstr-test.cpp
	g++ $(optdb) -o a64hexstr-test.o -c $(optcpp) $(optneon) hexstr-test.cpp

hexstr-a64c.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-a64c.o -c $(optc) $(optneon) hexstr.c

hexstr-a64intrin: a64mainh.o a64cpuinfo.o a64hexstr-test.o hexstr-a64intrin.o
	g++ $(optdb) -o hexstr-a64intrin $(optcpp) $(optneon) a64mainh.o a64cpuinfo.o a64hexstr-test.o hexstr-a64intrin.o

hexstr-a64intrin.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-a64intrin.o -c $(optc) $(optneon) -DUSE_SIMD hexstr.c

hexstr-a64asm: a64mainh.o a64cpuinfo.o a64hexstr-test.o hexstr-a64asm.o
	g++ $(optdb) -o hexstr-a64asm $(optcpp) $(optneon) a64mainh.o a64cpuinfo.o a64hexstr-test.o hexstr-a64asm.o

hexstr-a64asm.o: hexstr-a64.s
	as $(optdb) -o hexstr-a64asm.o $(optas) hexstr-a64.s

hexstr-neon64: a64mainh.o a64cpuinfo.o a64hexstr-test.o hexstr-neon64.o
	g++ $(optdb) -o hexstr-neon64 $(optcpp) $(optneon) a64mainh.o a64cpuinfo.o a64hexstr-test.o hexstr-neon64.o

hexstr-neon64.o: hexstr-neon64.s
	as $(optdb) -o hexstr-neon64.o $(optas) hexstr-neon64.s

a64maind.o: hexstr.h maind.cpp
	g++ $(optdb) -o a64maind.o -c $(optcpp) $(optneon) maind.cpp



#-----------------------------------------------------------------------------
# ARM32 code

arm32: hexstr-a32c hexstr-a32intrin hexstr-a32asm hexstr-neon32 hexstr-thumb

hexstr-a32c: a32main.o a32cpuinfo.o hexstr-a32c.o
	g++ $(optdb) -o hexstr-a32c $(optcpp) $(optneon) a32main.o a32cpuinfo.o hexstr-a32c.o

a32main.o: hexstr.h main.cpp
	g++ $(optdb) -o a32main.o -c $(optcpp) $(optneon) main.cpp

a32cpuinfo.o: cpuinfo.h cpuinfo.cpp
	g++ $(optdb) -o a32cpuinfo.o -c $(optcpp) $(optneon) cpuinfo.cpp

hexstr-a32c.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-a32c.o -c $(optc) $(optneon) hexstr.c

hexstr-a32intrin: a32main.o a32cpuinfo.o hexstr-a32intrin.o
	g++ $(optdb) -o hexstr-a32intrin $(optcpp) $(optneon) a32main.o a32cpuinfo.o hexstr-a32intrin.o

hexstr-a32intrin.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-a32intrin.o -c $(optc) $(optneon) -DUSE_SIMD hexstr.c

hexstr-a32asm: a32main.o hexstr-a32asm.o
	g++ $(optdb) -o hexstr-a32asm $(optcpp) $(optneon) a32main.o hexstr-a32asm.o

hexstr-a32asm.o: hexstr-a32.s
	as $(optdb) -o hexstr-a32asm.o $(optas) hexstr-a32.s

hexstr-neon32: a32main.o hexstr-neon32.o
	g++ $(optdb) -o hexstr-neon32 $(optcpp) $(optneon) a32main.o hexstr-neon32.o

hexstr-neon32.o: hexstr-neon32.s
	as $(optdb) -o hexstr-neon32.o $(optas) hexstr-neon32.s

hexstr-thumb: a32main.o hexstr-thumb.o
	g++ $(optdb) -o hexstr-thumb $(optcpp) $(optneon) a32main.o hexstr-thumb.o

hexstr-thumb.o: hexstr-thumb.s
	as $(optdb) -o hexstr-thumb.o $(optas) hexstr-thumb.s



# Quietly clean up

clean:
	rm -f cpuid hexstr-c hexstr-intrin hexstr-x64 hexstr-sse hexstr-avx hexstr-a64c hexstr-a64intrin hexstr-a64asm hexstr-neon64 hexstr-a32c hexstr-a32intrin hexstr-a32asm hexstr-neon32 hexstr-thumb decstr-c decstr-intrin decstr-x64 decstr-sse decstr-avx a.out *.o
