# hexstr

Intel SSE/AVX2 and ARM NEON hexadecimal string creation.
Inspired by the books "The Art of 64-Bit Assembly" and "The Art of ARM Assembly" by Randall Hyde.  
https://nostarch.com/art-64-bit-assembly-volume-1  
https://nostarch.com/art-arm-assembly  

This is a testbed for experimenting with SIMD implementations. For comparison purposes there are ordinary C and assembly implementations.

It's less interesting than hex, but I've added Intel SSE/AVX2 decimal string creation.

## Files  
makefile - macOS and Linux based builds.  
hexstr.mak - Windows based builds.  
timer.h - Determine elapsed time.  
cpuid.c - Displays cpu info  
cpuinfo.h  
cpuinfo.c - Gets CPU info and features.  
maind.cpp  
mainh.cpp - Timing code.  
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
decstr-x64.s - x86-64 assembly implementation (gas).  
decstr-sse.s - SSE implementation (gas).  
decstr-avx.s - AVX implementation (gas).  
decstr-x64.asm - x86-64 assembly implementation (masm).  
decstr-sse.asm - SSE implementation (masm).  
decstr-avx.asm - AVX implementation (masm).  
nextdigits.s - An include file to share macross and data (gas).  
nextdigits.asm - An include file to share macross and data (masm).  

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
gcc  -c -std=c17 -O3 cpuinfo.c
gcc  -o cpuid.o -c -std=c17 -O3 cpuid.c
gcc  -o cpuid -std=c17 -O3 cpuinfo.o cpuid.o
g++  -c -std=c++17 -O3 -march=haswell mainh.cpp
g++  -c -std=c++17 -O3 -march=haswell -o hexstr-test.o hexstr-test.cpp
gcc  -o hexstr-c.o -c -std=c17 -O3 -march=haswell hexstr.c
g++  -o hexstr-c -std=c++17 -O3 -march=haswell mainh.o cpuinfo.o hexstr-test.o hexstr-c.o
gcc  -o hexstr-intrin.o -c -std=c17 -O3 -march=haswell -DUSE_SIMD hexstr.c
g++  -o hexstr-intrin -std=c++17 -O3 -march=haswell mainh.o cpuinfo.o hexstr-test.o hexstr-intrin.o
as  -o hexstr-x64.o  hexstr-x64.s
Conditional Assembly: Lookup digits
Conditional Assembly: Output bytes
g++  -o hexstr-x64 -std=c++17 -O3 -march=haswell mainh.o cpuinfo.o hexstr-test.o hexstr-x64.o
as  -o hexstr-sse.o  hexstr-sse.s
g++  -o hexstr-sse -std=c++17 -O3 -march=haswell mainh.o cpuinfo.o hexstr-test.o hexstr-sse.o
as  -o hexstr-avx.o  hexstr-avx.s
g++  -o hexstr-avx -std=c++17 -O3 -march=haswell mainh.o cpuinfo.o hexstr-test.o hexstr-avx.o
g++  -c -std=c++17 -O3 -march=haswell -o maind.o maind.cpp
g++  -c -std=c++17 -O3 -march=haswell -o decstr-test.o decstr-test.cpp
as  -o decstr-x64.o  decstr-x64.s
g++  -o decstr-x64 -std=c++17 -O3 -march=haswell maind.o cpuinfo.o decstr-test.o decstr-x64.o
as  -o decstr-sse.o  decstr-sse.s
g++  -o decstr-sse -std=c++17 -O3 -march=haswell maind.o cpuinfo.o decstr-test.o decstr-sse.o
as  -o decstr-avx.o  decstr-avx.s
g++  -o decstr-avx -std=c++17 -O3 -march=haswell maind.o cpuinfo.o decstr-test.o decstr-avx.o
% ./hexstr-c
GenuineIntel Intel(R) Core(TM) i5-8259U CPU @ 2.30GHz
SSE3 SSE4.2 AVX AVX2 GEN4 
Tests complete
FEDCBA9876543210
FEDCBA9876543210 0123456789ABCDEF
76543210 89ABCDEF
3210 CDEF
10 EF
0 F
iterations: 100,000,000
snprintf: 72.47 ns
u64:      6.97 ns
u32:      4.26 ns
u16:      2.64 ns
u8:       2.14 ns
u4:       1.47 ns
% ./hexstr-intrin
...
u64:      2.12 ns
u32:      2.01 ns
u16:      1.87 ns
u8:       2.15 ns
u4:       1.47 ns
% ./hexstr-x64   
...
u64:      6.18 ns
u32:      3.54 ns
u16:      2.21 ns
u8:       1.82 ns
u4:       1.35 ns
% ./hexstr-sse
...
u64:      1.86 ns
u32:      1.74 ns
u16:      1.94 ns
u8:       1.92 ns
u4:       1.34 ns
% ./hexstr-avx
...
u64:      1.68 ns
u32:      1.61 ns
u16:      1.74 ns
u8:       1.90 ns
u4:       1.34 ns
% ./decstr-x64
GenuineIntel Intel(R) Core(TM) i5-8259U CPU @ 2.30GHz
SSE3 SSE4.2 AVX AVX2 GEN4 
Tests complete
18446744073709551615
18446744073709551615 09223372036854775807 -09223372036854775807
4294967295
4294967295 2147483647 -2147483647
iterations: 10,000,000
snprintf64: 85.46 ns
u64:        156.04 ns
s64:        156.71 ns
s64:        156.56 ns
snprintf32: 69.46 ns
u32:        65.98 ns
s32:        66.14 ns
s32:        66.98 ns
% ./decstr-sse
...
u64:        82.71 ns
s64:        81.59 ns
s64:        82.50 ns
u32:        20.58 ns
s32:        20.41 ns
s32:        20.71 ns
% ./decstr-avx
...
u64:        80.30 ns
s64:        80.72 ns
s64:        80.81 ns
u32:        18.08 ns
s32:        23.17 ns
s32:        21.91 ns
```

## To-do
Background task - reviewing and improving the code.  
