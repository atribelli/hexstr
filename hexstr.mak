# hexstr.mak

opt    = /O2 /EHsc
stdcpp = c++17
stdc   = c17

# General C / C++ code and intrinsics

all: hexstr-c.exe hexstr-intrin.exe hexstr-x64.exe hexstr-sse.exe

hexstr-c.exe: main.obj hexstr-c.obj
	cl /Fehexstr-c /std:$(stdcpp) $(opt) main.obj hexstr-c.obj

hexstr-c.obj: hexstr.h hexstr.c
	cl /Fohexstr-c /c /std:$(stdc) $(opt) hexstr.c

hexstr-intrin.exe: main.obj hexstr-intrin.obj
	cl /Fehexstr-intrin /std:$(stdcpp) $(opt) main.obj hexstr-intrin.obj

hexstr-intrin.obj: hexstr.h hexstr.c
	cl /Fohexstr-intrin /c /std:$(stdc) $(opt) /DUSE_SIMD hexstr.c

main.obj: hexstr.h main.cpp
	cl /c /std:$(stdcpp) $(opt) main.cpp

hexstr-x64.exe: main.obj hexstr-x64.obj
	cl /Fehexstr-x64 /std:$(stdcpp) $(opt) main.obj hexstr-x64.obj

hexstr-x64.obj: hexstr-x64.asm
	ml64 /c hexstr-x64.asm

hexstr-sse.exe: main.obj hexstr-sse.obj
	cl /Fehexstr-sse /std:$(stdcpp) $(opt) main.obj hexstr-sse.obj

hexstr-sse.obj: hexstr-sse.asm
	ml64 /c hexstr-sse.asm

# Quietly clean up

clean:
	del /q *.exe *.obj
