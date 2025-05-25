# hexstr-arm.mak

optcpp = /std:c++17 /O2 /EHsc
optc   = /std:c17 /O2 /EHsc

# General C / C++ code and intrinsics

all: hexstr-a64c.exe hexstr-a64intrin.exe # hexstr-a64.exe hexstr-a64neon.exe

hexstr-a64c.exe: a64mainh.obj hexstr-a64test.obj hexstr-a64c.obj
	cl /Fehexstr-a64c $(optcpp) a64mainh.obj hexstr-a64test.obj hexstr-a64c.obj

hexstr-a64c.obj: hexstr.h hexstr.c
	cl /Fohexstr-a64c /c $(optc) hexstr.c

hexstr-a64intrin.exe: a64mainh.obj hexstr-a64test.obj hexstr-a64intrin.obj
	cl /Fehexstr-a64intrin $(optcpp) a64mainh.obj hexstr-a64test.obj hexstr-a64intrin.obj

hexstr-a64intrin.obj: hexstr.h hexstr.c
	cl /Fohexstr-a64intrin /c $(optc) /DUSE_SIMD hexstr.c

hexstr-a64.exe: a64mainh.obj hexstr-a64test.obj hexstr-a64.obj
	cl /Fehexstr-a64 $(optcpp) a64mainh.obj hexstr-a64test.obj hexstr-a64.obj

hexstr-a64.obj: hexstr-a64.asm
	ml64 /c hexstr-a64.asm

hexstr-a64neon.exe: a64mainh.obj hexstr-a64test.obj hexstr-neon.obj
	cl /Fehexstr-a64neon $(optcpp) a64mainh.obj hexstr-a64test.obj hexstr-neon.obj

hexstr-neon.obj: hexstr-neon.asm
	ml64 /c hexstr-neon.asm

hexstr-a64test.obj: hexstr.h hexstr-test.h hexstr-test.cpp
	cl /Fohexstr-a64test /c $(optcpp) hexstr-test.cpp

a64mainh.obj: hexstr.h mainh.cpp
	cl /Foa64mainh /c $(optcpp) mainh.cpp

# Quietly clean up

clean:
	del /q *.exe *.obj
