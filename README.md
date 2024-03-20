# hexstr

Intel SSE/AVX2 and ARM NEON hexadecimal string creation.
Inspired by the books "The Art of 64-Bit Assembly" and "The Art of ARM Assembly" by Randall Hyde.  
https://nostarch.com/art-64-bit-assembly-volume-1  
https://nostarch.com/art-arm-assembly  

This is a testbed for experimenting with SIMD implementations. For comparison purposes there are ordinary C and assembly implementations.

## Files  
makefile - macOS and Linux based builds.  
hexstr.mak - Windows based builds.  
timer.h - Determine elapsed time.  
cpuinfo.h  
cpuinfo.cpp - Gets CPU info and features.  
main.cpp - Timing code.  
hexstr.h - Prototypes for hex string conversion functions.  
hexstr.c - C and SSE and NEON intrinsic implementations.  
hexstr-x64.s - x86-64 assembly implementation (gas).  
hexstr-sse.s - SSE implementation (gas).  
hexstr-avx.s - AVX implementation (gas).  
hexstr-a64.s - AArch64 assembly implementation.  
hexstr-neon64.s - AArch64 NEON implementation.  
hexstr-a32.s - ARMv7-A assembly implementation.  
hexstr-neon32.s - ARMv7-A NEON implementation.  
hexstr-thumb.s - ARMv7-A thumb implementation.  
hexstr-x64.asm - x86-64 assembly implementation (masm).  
hexstr-sse.asm - SSE implementation (masm).  
hexstr-avx.asm - AVX implementation (masm).  

## Building  
make - Create C and intrinsics based code: hexstr-c and hexstr-intrin.  
make intel - Create x64 assembly, SSE, and AVX code: hexstr-x64, hexstr-sse, and hexstr-avx.  
make arm64 - Create AArch64 assembly and NEON code: hexstr-a64 and hexstr-neon64.  
make arm32 - Create ARMv7-A assembly, NEON, and thumb code: hexstr-a32, hexstr-neon32, and hexstr-thumb.  
make clean - Remove executable and build files.  
nmake /f hexstr.mak - Create all executables for Windows.  
nmake /f hexstr.mak clean - Remove executable and build files under Windows.  

## Testing  
Intel based Mac.  
Windows PC.  
Linux PC.  
Raspberry Pi 64-bit.  
Raspberry Pi 32-bit.  

## Algorithms  
Previous experience has shown that different algorithms may be faster depending on the underlying hardware architecture. C based implementations use unrolled table-based lookup. Assembly based implementation have four options. Table lookup or computed hex digits. Copying individual digits to the output buffer or collecting digits in a register and only copying to the output buffer when the register is full. The assembly code has a pair of symbols defined to choose these algorithm options:  
use_table - Table lookup if defined, computed if undefined.  
use_bytes - Byte output if defined, full register output if undefined.  
Note that the value of the defined symbol does not matter. Conditional assembly is using .ifdef not .if. So, comment or uncomment the definitions as desired. During assembly the assembler will output messages indicating the current algorithm settings.  

## Example  
```
% make intel
g++  -c -std=c++17 -O3 -march=haswell main.cpp
g++  -c -std=c++17 -O3 -march=haswell cpuinfo.cpp
gcc  -o hexstr-c.o -c -std=c17 -O3 -march=haswell hexstr.c
g++  -o hexstr-c -std=c++17 -O3 -march=haswell main.o cpuinfo.o hexstr-c.o
gcc  -o hexstr-intrin.o -c -std=c17 -O3 -march=haswell -DUSE_SIMD hexstr.c
g++  -o hexstr-intrin -std=c++17 -O3 -march=haswell main.o cpuinfo.o hexstr-intrin.o
as  -o hexstr-x64.o  hexstr-x64.s
Conditional Assembly: Lookup digits
Conditional Assembly: Output bytes
g++  -o hexstr-x64asm -std=c++17 -O3 -march=haswell main.o cpuinfo.o hexstr-x64.o
as  -o hexstr-sse.o  hexstr-sse.s
g++  -o hexstr-sse -std=c++17 -O3 -march=haswell main.o cpuinfo.o hexstr-sse.o
as  -o hexstr-avx.o  hexstr-avx.s
g++  -o hexstr-avx -std=c++17 -O3 -march=haswell main.o cpuinfo.o hexstr-avx.o
% ./hexstr-c
Intel(R) Core(TM) i5-8259U CPU @ 2.30GHz
FEDCBA9876543210 0123456789ABCDEF
76543210 89ABCDEF
3210 CDEF
10 EF
0 F
iterations: 100,000,000
u64:   706 ms
u32:   424 ms
u16:   265 ms
u8:    185 ms
u4:    146 ms
% ./hexstr-intrin 
...
u64:   217 ms
u32:   211 ms
u16:   186 ms
u8:    189 ms
u4:    146 ms
% ./hexstr-x64asm 
...
u64:   650 ms
u32:   354 ms
u16:   216 ms
u8:    182 ms
u4:    133 ms
% ./hexstr-sse    
...
u64:   192 ms
u32:   182 ms
u16:   187 ms
u8:    186 ms
u4:    116 ms
% ./hexstr-avx
...
u64:   176 ms
u32:   167 ms
u16:   177 ms
u8:    185 ms
u4:    137 ms
```

## To-do
Background task - reviewing and improving the code.  

