# makefile

opt    = -O3
stdcpp = c++17
stdc   = c17

# General C / C++ code and intrinsics

all: hexstr-c hexstr-intrin

hexstr-c: main.o hexstr-c.o
	g++ -o hexstr-c -std=$(stdcpp) $(opt) main.o hexstr-c.o

hexstr-c.o: hexstr.h hexstr.c
	gcc -o hexstr-c.o -c -std=$(stdc) $(opt) hexstr.c

hexstr-intrin: main.o hexstr-intrin.o
	g++ -o hexstr-intrin -std=$(stdcpp) $(opt) main.o hexstr-intrin.o

hexstr-intrin.o: hexstr.h hexstr.c
	gcc -o hexstr-intrin.o -c -std=$(stdc) $(opt) -DUSE_SIMD hexstr.c

main.o: hexstr.h main.cpp
	g++ -c -std=$(stdcpp) $(opt) main.cpp

# ARM assembly language code

arm: hexstr-a64 hexstr-neon

hexstr-a64: main.o hexstr-a64.o
	g++ -o hexstr-a64 -std=$(stdcpp) $(opt) main.o hexstr-a64.o

hexstr-a64.o: hexstr-a64.s
	as -o hexstr-a64.o hexstr-a64.s

hexstr-neon: main.o hexstr-neon.o
	g++ -o hexstr-neon -std=$(stdcpp) $(opt) main.o hexstr-neon.o

hexstr-neon.o: hexstr-neon.s
	as -o hexstr-neon.o hexstr-neon.s

# Intel assembly language code

intel: hexstr-x64 hexstr-sse

hexstr-x64: main.o hexstr-x64.o
	g++ -o hexstr-x64 -std=$(stdcpp) $(opt) main.o hexstr-x64.o

hexstr-x64.o: hexstr-x64.s
	as -o hexstr-x64.o hexstr-x64.s

hexstr-sse: main.o hexstr-sse.o
	g++ -o hexstr-sse -std=$(stdcpp) $(opt) main.o hexstr-sse.o

hexstr-sse.o: hexstr-sse.s
	as -o hexstr-sse.o hexstr-sse.s

# Quietly clean up

clean:
	rm -f hexstr-c hexstr-intrin hexstr-a64 hexstr-neon hexstr-x64 hexstr-sse a.out *.o
