# hexstr-arm.mak

optcpp = /std:c++17 /O2 /EHsc
optc   = /std:c17 /O2 /EHsc

# General C / C++ code and intrinsics

all: a64cpuid.exe hexstr-a64c.exe hexstr-a64asm.exe hexstr-a64intrin.exe hexstr-a64neon.exe

a64cpuid.exe: a64cpuid.obj a64cpuinfo.obj
	cl /Fea64cpuid $(optc) a64cpuinfo.obj a64cpuid.obj

a64cpuid.obj: cpuinfo.h cpuid.c
	cl /c /Foa64cpuid $(optc) cpuid.c

a64cpuinfo.obj: cpuinfo.h cpuinfo.c
	cl /c /Foa64cpuinfo $(optc) cpuinfo.c

a64midr.obj: midr.asm
	armasm64 -o a64midr.obj midr.asm

hexstr-a64c.exe: a64mainh.obj a64cpuinfo.obj hexstr-a64test.obj hexstr-a64c.obj
	cl /Fehexstr-a64c $(optcpp) a64mainh.obj a64cpuinfo.obj hexstr-a64test.obj hexstr-a64c.obj

hexstr-a64c.obj: hexstr.h hexstr.c
	cl /Fohexstr-a64c /c $(optc) hexstr.c

hexstr-a64asm.exe: a64mainh.obj a64cpuinfo.obj hexstr-a64test.obj hexstr-a64asm.obj
	cl /Fehexstr-a64asm $(optcpp) a64mainh.obj a64cpuinfo.obj hexstr-a64test.obj hexstr-a64asm.obj

hexstr-a64asm.obj: hexstr-a64.asm
	armasm64 -o hexstr-a64asm.obj hexstr-a64.asm

hexstr-a64intrin.exe: a64mainh.obj a64cpuinfo.obj hexstr-a64test.obj hexstr-a64intrin.obj
	cl /Fehexstr-a64intrin $(optcpp) a64mainh.obj a64cpuinfo.obj hexstr-a64test.obj hexstr-a64intrin.obj

hexstr-a64intrin.obj: hexstr.h hexstr.c
	cl /Fohexstr-a64intrin /c $(optc) /DUSE_SIMD hexstr.c

hexstr-a64neon.exe: a64mainh.obj a64cpuinfo.obj hexstr-a64test.obj hexstr-neon.obj
	cl /Fehexstr-a64neon $(optcpp) a64mainh.obj a64cpuinfo.obj hexstr-a64test.obj hexstr-neon.obj

hexstr-neon.obj: hexstr-neon.asm
	armasm64 hexstr-neon.asm

hexstr-a64test.obj: hexstr.h hexstr-test.h hexstr-test.cpp
	cl /Fohexstr-a64test /c $(optcpp) hexstr-test.cpp

a64mainh.obj: hexstr.h mainh.cpp
	cl /Foa64mainh /c $(optcpp) mainh.cpp

# Quietly clean up

clean:
	del /q *.exe *.obj
