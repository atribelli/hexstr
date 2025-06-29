# makefile



#-----------------------------------------------------------------------------
# Determine the current environment

platform := $(shell uname -m)
kernel   := $(shell uname -s)
wordsize := $(shell getconf LONG_BIT)

# Set variables for the current environment
# and determine which set of build commands to execute

optcpp = -std=c++17 -O3
optc   = -std=c17 -O3
#optdb  = -g

ifeq ($(kernel), Darwin)

$(info macOS detected)
optas =

ifeq ($(platform), x86_64)

$(info Intel detected)
optarch = -march=haswell
target  = intel

else ifeq ($(platform), arm64)

$(info ARM detected)
optarch = -march=armv8-a
target  = arm64

endif   # ARM, Intel

else ifeq ($(kernel), Linux)

$(info Linux detected)
optas = --defsym IsLinux=1  # Linux assembly needs GNU specific section

ifeq ($(wordsize), 32)      # ARM-v7a is the only supported 32-bit architecture

$(info ARM32 detected)
optarch = -march=armv7-a -mfpu=neon-vfpv3
target  = arm32

else ifeq ($(platform), x86_64)

$(info Intel detected)
optarch = -march=haswell
target  = intel

else ifeq ($(platform), aarch64)

$(info ARM detected)
optarch = -march=armv8-a
target  = arm64

endif   # ARM, Intel, 32-bit
endif   # Linux, Darwin

all: $(target)
	@echo $(target) done



#-----------------------------------------------------------------------------
# Intel x64 code

intel: cpuid hexstr-c hexstr-x64 hexstr-intrin hexstr-sse hexstr-avx decstr-c decstr-intrin decstr-x64 decstr-sse decstr-avx

cpuid: cpuinfo.o cpuid.o
	gcc $(optdb) -o cpuid $(optc) cpuinfo.o cpuid.o

cpuid.o: cpuinfo.h cpuid.c
	gcc $(optdb) -o cpuid.o -c $(optc) cpuid.c

cpuinfo.o: cpuinfo.h cpuinfo.c
	gcc $(optdb) -c $(optc) cpuinfo.c

hexstr-c: mainh.o cpuinfo.o hexstr-test.o hexstr-c.o
	g++ $(optdb) -o hexstr-c $(optcpp) $(optarch) mainh.o cpuinfo.o hexstr-test.o hexstr-c.o

hexstr-c.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-c.o -c $(optc) $(optarch) hexstr.c

hexstr-x64: mainh.o cpuinfo.o hexstr-test.o hexstr-x64.o
	g++ $(optdb) -o hexstr-x64 $(optcpp) $(optarch) mainh.o cpuinfo.o hexstr-test.o hexstr-x64.o

hexstr-x64.o: hexstr-x64.s
	as $(optdb) -o hexstr-x64.o $(optas) hexstr-x64.s

hexstr-intrin: mainh.o cpuinfo.o hexstr-test.o hexstr-intrin.o
	g++ $(optdb) -o hexstr-intrin $(optcpp) $(optarch) mainh.o cpuinfo.o hexstr-test.o hexstr-intrin.o

hexstr-intrin.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-intrin.o -c $(optc) $(optarch) -DUSE_SIMD hexstr.c

hexstr-sse: mainh.o cpuinfo.o hexstr-test.o hexstr-sse.o
	g++ $(optdb) -o hexstr-sse $(optcpp) $(optarch) mainh.o cpuinfo.o hexstr-test.o hexstr-sse.o

hexstr-sse.o: hexstr-sse.s
	as $(optdb) -o hexstr-sse.o $(optas) hexstr-sse.s

hexstr-avx: mainh.o cpuinfo.o hexstr-test.o hexstr-avx.o
	g++ $(optdb) -o hexstr-avx $(optcpp) $(optarch) mainh.o cpuinfo.o hexstr-test.o hexstr-avx.o

hexstr-avx.o: hexstr-avx.s
	as $(optdb) -o hexstr-avx.o $(optas) hexstr-avx.s

hexstr-test.o: hexstr.h hexstr-test.cpp
	g++ $(optdb) -c $(optcpp) $(optarch) -o hexstr-test.o hexstr-test.cpp

mainh.o: hexstr.h mainh.cpp
	g++ $(optdb) -c $(optcpp) $(optarch) mainh.cpp

decstr-c: maind.o cpuinfo.o decstr-test.o decstr-c.o
	g++ $(optdb) -o decstr-c $(optcpp) $(optarch) maind.o cpuinfo.o decstr-test.o decstr-c.o

decstr-c.o: decstr.h decstr.c
	gcc $(optdb) -o decstr-c.o -c $(optc) $(optarch) decstr.c

decstr-intrin: maind.o cpuinfo.o decstr-test.o decstr-intrin.o
	g++ $(optdb) -o decstr-intrin $(optcpp) $(optarch) maind.o cpuinfo.o decstr-test.o decstr-intrin.o

decstr-intrin.o: decstr.h decstr.c
	gcc $(optdb) -o decstr-intrin.o -c $(optc) $(optarch) -DUSE_SIMD decstr.c

decstr-x64: maind.o cpuinfo.o decstr-test.o decstr-x64.o
	g++ $(optdb) -o decstr-x64 $(optcpp) $(optarch) maind.o cpuinfo.o decstr-test.o decstr-x64.o

decstr-x64.o: nextdigits.s decstr-x64.s
	as $(optdb) -o decstr-x64.o $(optas) decstr-x64.s

decstr-sse: maind.o cpuinfo.o decstr-test.o decstr-sse.o
	g++ $(optdb) -o decstr-sse $(optcpp) $(optarch) maind.o cpuinfo.o decstr-test.o decstr-sse.o

decstr-sse.o: nextdigits.s decstr-sse.s
	as $(optdb) -o decstr-sse.o $(optas) decstr-sse.s

decstr-avx: maind.o cpuinfo.o decstr-test.o decstr-avx.o
	g++ $(optdb) -o decstr-avx $(optcpp) $(optarch) maind.o cpuinfo.o decstr-test.o decstr-avx.o

decstr-avx.o: nextdigits.s decstr-avx.s
	as $(optdb) -o decstr-avx.o $(optas) decstr-avx.s

decstr-test.o: decstr.h decstr-test.cpp
	g++ $(optdb) -c $(optcpp) $(optarch) -o decstr-test.o decstr-test.cpp

maind.o: decstr.h maind.cpp
	g++ $(optdb) -c $(optcpp) $(optarch) -o maind.o maind.cpp



#-----------------------------------------------------------------------------
# ARM64 code

arm64: a64cpuid hexstr-a64c hexstr-a64asm hexstr-a64intrin hexstr-a64neon

a64cpuid: a64cpuinfo.o a64midr.o a64cpuid.o
	gcc $(optdb) -o a64cpuid $(optc) a64cpuinfo.o a64midr.o a64cpuid.o

a64cpuid.o: cpuinfo.h cpuid.c
	gcc $(optdb) -o a64cpuid.o -c $(optc) cpuid.c

a64cpuinfo.o: cpuinfo.h midr.h cpuinfo.c
	gcc $(optdb) -o a64cpuinfo.o -c $(optc) cpuinfo.c

a64midr.o: midr.h midr-a64.s
	as $(optdb) -o a64midr.o $(optas) midr-a64.s

hexstr-a64c: a64mainh.o a64cpuinfo.o a64midr.o a64hexstr-test.o hexstr-a64c.o
	g++ $(optdb) -o hexstr-a64c $(optcpp) $(optarch) a64mainh.o a64cpuinfo.o a64midr.o a64hexstr-test.o hexstr-a64c.o

a64mainh.o: hexstr.h mainh.cpp
	g++ $(optdb) -o a64mainh.o -c $(optcpp) $(optarch) mainh.cpp

a64hexstr-test.o: hexstr.h hexstr-test.cpp
	g++ $(optdb) -o a64hexstr-test.o -c $(optcpp) $(optarch) hexstr-test.cpp

hexstr-a64c.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-a64c.o -c $(optc) $(optarch) hexstr.c

hexstr-a64asm: a64mainh.o a64cpuinfo.o a64midr.o a64hexstr-test.o hexstr-a64asm.o
	g++ $(optdb) -o hexstr-a64asm $(optcpp) $(optarch) a64mainh.o a64cpuinfo.o a64midr.o a64hexstr-test.o hexstr-a64asm.o

hexstr-a64asm.o: hexstr-a64.s
	as $(optdb) -o hexstr-a64asm.o $(optas) hexstr-a64.s

hexstr-a64intrin: a64mainh.o a64cpuinfo.o a64midr.o a64hexstr-test.o hexstr-a64intrin.o
	g++ $(optdb) -o hexstr-a64intrin $(optcpp) $(optarch) a64mainh.o a64cpuinfo.o a64midr.o a64hexstr-test.o hexstr-a64intrin.o

hexstr-a64intrin.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-a64intrin.o -c $(optc) $(optarch) -DUSE_SIMD hexstr.c

hexstr-a64neon: a64mainh.o a64cpuinfo.o a64midr.o a64hexstr-test.o hexstr-a64neon.o
	g++ $(optdb) -o hexstr-a64neon $(optcpp) $(optarch) a64mainh.o a64cpuinfo.o a64midr.o a64hexstr-test.o hexstr-a64neon.o

hexstr-a64neon.o: hexstr-neon64.s
	as $(optdb) -o hexstr-a64neon.o $(optas) hexstr-neon64.s

a64maind.o: hexstr.h maind.cpp
	g++ $(optdb) -o a64maind.o -c $(optcpp) $(optarch) maind.cpp



#-----------------------------------------------------------------------------
# ARM32 code

arm32: a32cpuid hexstr-a32c hexstr-a32asm hexstr-a32intrin hexstr-a32neon hexstr-t32asm

a32cpuid: a32cpuinfo.o a32cpuid.o
	gcc $(optdb) -o a32cpuid $(optc) a32cpuinfo.o a32cpuid.o

a32cpuid.o: cpuinfo.h cpuid.c
	gcc $(optdb) -o a32cpuid.o -c $(optc) cpuid.c

a32cpuinfo.o: cpuinfo.h cpuinfo.c
	gcc $(optdb) -o a32cpuinfo.o -c $(optc) cpuinfo.c

hexstr-a32c: a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-a32c.o
	g++ $(optdb) -o hexstr-a32c $(optcpp) $(optarch) a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-a32c.o

a32main.o: hexstr.h mainh.cpp
	g++ $(optdb) -o a32main.o -c $(optcpp) $(optarch) mainh.cpp

a32hexstr-test.o: hexstr.h hexstr-test.cpp
	g++ $(optdb) -o a32hexstr-test.o -c $(optcpp) $(optarch) hexstr-test.cpp

hexstr-a32c.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-a32c.o -c $(optc) $(optarch) hexstr.c

hexstr-a32asm: a32main.o a32cpuinfo.o a32hexstr-test.o  hexstr-a32asm.o
	g++ $(optdb) -o hexstr-a32asm $(optcpp) $(optarch) a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-a32asm.o

hexstr-a32asm.o: hexstr-a32.s
	as $(optdb) -o hexstr-a32asm.o $(optas) hexstr-a32.s

hexstr-a32intrin: a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-a32intrin.o
	g++ $(optdb) -o hexstr-a32intrin $(optcpp) $(optarch) a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-a32intrin.o

hexstr-a32intrin.o: hexstr.h hexstr.c
	gcc $(optdb) -o hexstr-a32intrin.o -c $(optc) $(optarch) -DUSE_SIMD hexstr.c

hexstr-a32neon: a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-a32neon.o
	g++ $(optdb) -o hexstr-a32neon $(optcpp) $(optarch) a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-a32neon.o

hexstr-a32neon.o: hexstr-neon32.s
	as $(optdb) -o hexstr-a32neon.o $(optas) hexstr-neon32.s

hexstr-t32asm: a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-t32asm.o
	g++ $(optdb) -o hexstr-t32asm $(optcpp) $(optarch) a32main.o a32cpuinfo.o a32hexstr-test.o hexstr-t32asm.o

hexstr-t32asm.o: hexstr-t32.s
	as $(optdb) -o hexstr-t32asm.o $(optas) hexstr-t32.s



# Quietly clean up

clean:
	rm -f cpuid a64cpuid a32cpuid hexstr-c hexstr-intrin hexstr-x64 hexstr-sse hexstr-avx hexstr-a64c hexstr-a64intrin hexstr-a64asm hexstr-a64neon hexstr-a32c hexstr-a32intrin hexstr-a32asm hexstr-a32neon hexstr-t32asm decstr-c decstr-intrin decstr-x64 decstr-sse decstr-avx a.out *.o
