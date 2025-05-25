# hexstr

Intel SSE/AVX2 and ARM NEON hexadecimal string creation.
Inspired by the books by Randall Hyde:  
"The Art of 64-Bit Assembly, Volume 1"  
ISBN-13: 9781718501089  
https://nostarch.com/art-64-bit-assembly-volume-1  
https://www.amazon.com/Art-64-Bit-Assembly-Language/dp/1718501080  
"The Art of ARM Assembly, Volume 1"  
ISBN-13: 9781718502826  
https://nostarch.com/art-arm-assembly  
https://www.amazon.com/Art-ARM-Assembly-Randall-Hyde/dp/1718502826  

This is a testbed for experimenting with SIMD implementations. For comparison purposes there are ordinary C and assembly implementations.

It's less interesting than hex, but I've added Intel SSE/AVX2 decimal string creation.

## Files  
makefile - macOS and Linux based builds.  
hexstr.mak - Windows based builds.  
timer.h - Determine elapsed time.  
cpuid.c - Displays cpu info.  
cpuinfo.h  
cpuinfo.c - Gets CPU info and features.  
maind.cpp  
mainh.cpp - Timing code.  
hexstr.h - Prototypes for hex string conversion functions.  
hexstr.c - C and SSE and NEON intrinsic implementations.  
hexstr-test.h  
hexstr-test.cpp - Result testing.  
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
decstr.h - Prototypes for decimal string conversion functions.  
decstr.c - C and SSE and NEON intrinsic implementations.  
decstr-test.h  
decstr-test.cpp - Result testing.  
decstr-x64.s - x86-64 assembly implementation (gas).  
decstr-sse.s - SSE implementation (gas).  
decstr-avx.s - AVX implementation (gas).  
decstr-x64.asm - x86-64 assembly implementation (masm).  
decstr-sse.asm - SSE implementation (masm).  
decstr-avx.asm - AVX implementation (masm).  
nextdigits.s - An include file to share macross and data (gas).  
nextdigits.asm - An include file to share macross and data (masm).  

## Building  
make - Detects OS and architecture and builds intel, arm64, or arm32 code.  
intel: cpuid, hexstr-c, hexstr-intrin, hexstr-x64, hexstr-sse, hexstr-avx, decstr-c, decstr-intrin, decstr-x64, decstr-sse, and decstr-avx.  
arm64: hexstr-a64c, hexstr-a64intrin, hexstr-a64asm, and hexstr-a64neon.  
arm32: hexstr-a32c, hexstr-a32intrin, hexstr-a32asm, hexstr-a32neon, and hexstr-thumb.  
make clean - Remove executable and build files.  
nmake /f hexstr.mak - Create all executables for Windows.  
intel: cpuid.exe, hexstr-c.exe, hexstr-intrin.exe, hexstr-x64.exe, hexstr-sse.exe, hexstr-avx.exe, decstr-c.exe, decstr-intrin.exe, decstr-x64.exe, decstr-sse.exe, and decstr-avx.exe.  
nmake /f hexstr.mak clean - Remove executable and build files under Windows.  

## Testing  
Intel based Mac.  
ARM based Mac.  
Intel based Windows PC.  
Intel based Linux PC.  
ARM based Linux PC (Virtualized on Mac).  
Raspberry Pi 64-bit (ARM64 Linux).  
Raspberry Pi 32-bit (ARM32 Linux).  

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
gcc  -o decstr-c.o -c -std=c17 -O3 -march=haswell decstr.c
g++  -o decstr-c -std=c++17 -O3 -march=haswell maind.o cpuinfo.o decstr-test.o decstr-c.o
gcc  -o decstr-intrin.o -c -std=c17 -O3 -march=haswell -DUSE_SIMD decstr.c
g++  -o decstr-intrin -std=c++17 -O3 -march=haswell maind.o cpuinfo.o decstr-test.o decstr-intrin.o
as  -o decstr-x64.o  decstr-x64.s
g++  -o decstr-x64 -std=c++17 -O3 -march=haswell maind.o cpuinfo.o decstr-test.o decstr-x64.o
as  -o decstr-sse.o  decstr-sse.s
g++  -o decstr-sse -std=c++17 -O3 -march=haswell maind.o cpuinfo.o decstr-test.o decstr-sse.o
as  -o decstr-avx.o  decstr-avx.s
g++  -o decstr-avx -std=c++17 -O3 -march=haswell maind.o cpuinfo.o decstr-test.o decstr-avx.o
% ./hexstr-c
GenuineIntel Intel(R) Core(TM) i5-8500B CPU @ 3.00GHz
SSE3 SSE4.2 AVX AVX2 GEN4 
Tests complete
FEDCBA9876543210
FEDCBA9876543210 0123456789ABCDEF
76543210 89ABCDEF
3210 CDEF
10 EF
0 F
iterations: 100,000,000
snprintf: 67.83 ns
u64:      6.52 ns
u32:      3.99 ns
u16:      2.49 ns
u8:       2.02 ns
u4:       1.39 ns
% ./hexstr-x64
...
u64:      5.77 ns
u32:      3.29 ns
u16:      2.08 ns
u8:       1.59 ns
u4:       1.25 ns
% ./hexstr-intrin 
...
u64:      2.02 ns
u32:      2.10 ns
u16:      2.27 ns
u8:       1.74 ns
u4:       1.37 ns
% ./hexstr-sse   
...
u64:      1.74 ns
u32:      1.63 ns
u16:      1.74 ns
u8:       1.72 ns
u4:       1.24 ns
% ./hexstr-avx
...
u64:      1.55 ns
u32:      1.51 ns
u16:      1.61 ns
u8:       1.75 ns
u4:       1.25 ns
% ./decstr-c     
GenuineIntel Intel(R) Core(TM) i5-8500B CPU @ 3.00GHz
SSE3 SSE4.2 AVX AVX2 GEN4 
Tests complete
18446744073709551615
18446744073709551615 09223372036854775807 -09223372036854775807
4294967295
4294967295 2147483647 -2147483647
iterations: 10,000,000
snprintf64: 78.71 ns
u64:        121.68 ns
s64:        123.83 ns
s64:        124.77 ns
snprintf32: 64.14 ns
u32:        36.49 ns
s32:        36.60 ns
s32:        36.29 ns
% ./decstr-x64
...
u64:        115.61 ns
s64:        116.41 ns
s64:        116.68 ns
u32:        31.82 ns
s32:        32.51 ns
s32:        34.68 ns
% ./decstr-intrin 
...
u64:        71.84 ns
s64:        72.74 ns
s64:        73.11 ns
u32:        24.91 ns
s32:        24.95 ns
s32:        24.14 ns
% ./decstr-sse   
...
u64:        69.52 ns
s64:        69.08 ns
s64:        69.81 ns
u32:        19.31 ns
s32:        19.32 ns
s32:        19.81 ns
% ./decstr-avx
...
u64:        65.96 ns
s64:        66.21 ns
s64:        66.29 ns
u32:        16.42 ns
s32:        17.63 ns
s32:        20.28 ns
```

## To-do
Background task - reviewing and improving the code.  
