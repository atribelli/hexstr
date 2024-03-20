# hexstr.mak

optcpp = /std:c++17 /O2 /EHsc
optc   = /std:c17 /O2 /EHsc

# General C / C++ code and intrinsics

all: hexstr-c.exe hexstr-intrin.exe hexstr-x64.exe hexstr-sse.exe hexstr-avx.exe

hexstr-c.exe: main.obj cpuinfo.obj hexstr-c.obj
	cl /Fehexstr-c $(optcpp) main.obj cpuinfo.obj hexstr-c.obj

hexstr-c.obj: hexstr.h hexstr.c
	cl /Fohexstr-c /c $(optc) hexstr.c

hexstr-intrin.exe: main.obj cpuinfo.obj hexstr-intrin.obj
	cl /Fehexstr-intrin $(optcpp) main.obj cpuinfo.obj hexstr-intrin.obj

hexstr-intrin.obj: hexstr.h hexstr.c
	cl /Fohexstr-intrin /c $(optc) /DUSE_SIMD hexstr.c

main.obj: hexstr.h main.cpp
	cl /c $(optcpp) main.cpp

cpuinfo.obj: cpuinfo.h cpuinfo.cpp
	cl /c $(optcpp) cpuinfo.cpp

hexstr-x64.exe: main.obj cpuinfo.obj hexstr-x64.obj
	cl /Fehexstr-x64 $(optcpp) main.obj cpuinfo.obj hexstr-x64.obj

hexstr-x64.obj: hexstr-x64.asm
	ml64 /c hexstr-x64.asm

hexstr-sse.exe: main.obj cpuinfo.obj hexstr-sse.obj
	cl /Fehexstr-sse $(optcpp) main.obj cpuinfo.obj hexstr-sse.obj

hexstr-sse.obj: hexstr-sse.asm
	ml64 /c hexstr-sse.asm

hexstr-avx.exe: main.obj cpuinfo.obj hexstr-avx.obj
	cl /Fehexstr-avx $(optcpp) main.obj cpuinfo.obj hexstr-avx.obj

hexstr-avx.obj: hexstr-avx.asm
	ml64 /c hexstr-avx.asm

# Quietly clean up

clean:
	del /q *.exe *.obj
