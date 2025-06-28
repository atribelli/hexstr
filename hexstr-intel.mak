# hexstr-intel.mak

optcpp = /std:c++17 /O2 /EHsc
optc   = /std:c17 /O2 /EHsc

# General C / C++ code and intrinsics

all: cpuid.exe hexstr-c.exe hexstr-x64.exe hexstr-intrin.exe hexstr-sse.exe \
     hexstr-avx.exe decstr-c.exe decstr-intrin.exe decstr-x64.exe \
	 decstr-sse.exe decstr-avx.exe

cpuid.exe: cpuid.obj cpuinfo.obj
	cl /Fecpuid $(optc) cpuinfo.obj cpuid.obj

cpuid.obj: cpuinfo.h cpuid.c
	cl /c $(optc) cpuid.c

cpuinfo.obj: cpuinfo.h cpuinfo.c
	cl /c $(optc) cpuinfo.c

hexstr-c.exe: mainh.obj cpuinfo.obj hexstr-test.obj hexstr-c.obj
	cl /Fehexstr-c $(optcpp) mainh.obj cpuinfo.obj hexstr-test.obj hexstr-c.obj

hexstr-c.obj: hexstr.h hexstr.c
	cl /Fohexstr-c /c $(optc) hexstr.c

hexstr-x64.exe: mainh.obj cpuinfo.obj hexstr-test.obj hexstr-x64.obj
	cl /Fehexstr-x64 $(optcpp) mainh.obj cpuinfo.obj hexstr-test.obj hexstr-x64.obj

hexstr-x64.obj: hexstr-x64.asm
	ml64 /c hexstr-x64.asm

hexstr-intrin.exe: mainh.obj cpuinfo.obj hexstr-test.obj hexstr-intrin.obj
	cl /Fehexstr-intrin $(optcpp) mainh.obj cpuinfo.obj hexstr-test.obj hexstr-intrin.obj

hexstr-intrin.obj: hexstr.h hexstr.c
	cl /Fohexstr-intrin /c $(optc) /DUSE_SIMD hexstr.c

hexstr-sse.exe: mainh.obj cpuinfo.obj hexstr-test.obj hexstr-sse.obj
	cl /Fehexstr-sse $(optcpp) mainh.obj cpuinfo.obj hexstr-test.obj hexstr-sse.obj

hexstr-sse.obj: hexstr-sse.asm
	ml64 /c hexstr-sse.asm

hexstr-avx.exe: mainh.obj cpuinfo.obj hexstr-test.obj hexstr-avx.obj
	cl /Fehexstr-avx $(optcpp) mainh.obj cpuinfo.obj hexstr-test.obj hexstr-avx.obj

hexstr-avx.obj: hexstr-avx.asm
	ml64 /c hexstr-avx.asm

hexstr-test.obj: hexstr.h hexstr-test.h hexstr-test.cpp
	cl /c $(optcpp) hexstr-test.cpp

mainh.obj: hexstr.h mainh.cpp
	cl /c $(optcpp) mainh.cpp

decstr-c.exe: maind.obj cpuinfo.obj decstr-test.obj decstr-c.obj
	cl /Fedecstr-c $(optcpp) maind.obj cpuinfo.obj decstr-test.obj decstr-c.obj

decstr-c.obj: decstr.h decstr.c
	cl /Fodecstr-c /c $(optc) decstr.c

decstr-intrin.exe: maind.obj cpuinfo.obj decstr-test.obj decstr-intrin.obj
	cl /Fedecstr-intrin $(optcpp) maind.obj cpuinfo.obj decstr-test.obj decstr-intrin.obj

decstr-intrin.obj: decstr.h decstr.c
	cl /Fodecstr-intrin /c $(optc) /DUSE_SIMD decstr.c

decstr-x64.exe: maind.obj cpuinfo.obj decstr-test.obj decstr-x64.obj
	cl /Fedecstr-x64 $(optcpp) maind.obj cpuinfo.obj decstr-test.obj decstr-x64.obj

decstr-x64.obj: nextdigits.asm decstr-x64.asm
	ml64 /c decstr-x64.asm

decstr-sse.exe: maind.obj cpuinfo.obj decstr-test.obj decstr-sse.obj
	cl /Fedecstr-sse $(optcpp) maind.obj cpuinfo.obj decstr-test.obj decstr-sse.obj

decstr-sse.obj: nextdigits.asm decstr-sse.asm
	ml64 /c decstr-sse.asm

decstr-avx.exe: maind.obj cpuinfo.obj decstr-test.obj decstr-avx.obj
	cl /Fedecstr-avx $(optcpp) maind.obj cpuinfo.obj decstr-test.obj decstr-avx.obj

decstr-avx.obj: nextdigits.asm decstr-avx.asm
	ml64 /c decstr-avx.asm

decstr-test.obj: decstr.h decstr-test.h decstr-test.cpp
	cl /c $(optcpp) decstr-test.cpp

maind.obj: decstr.h decstr-test.h  maind.cpp
	cl /c $(optcpp) maind.cpp

# Quietly clean up

clean:
	del /q *.exe *.obj
