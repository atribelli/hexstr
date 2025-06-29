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

.mak and .asm files are Windows specific.  
makefile and .s files are macOS and Linux specific.  
.h, .c, and .cpp files are uaually cross-platform.  
"a32" in name indicates 32-bit ARM.  
"a64" indicates 64-bit ARM.  
"t32" indicates ARM Thumb code.  
"x64" indicates X86_64.  

makefile - macOS and Linux based builds.  
hexstr-intel.mak - Windows based builds.  
hexstr-arm.mak  
timer.h - Determine elapsed time.  
cpuid.c - Displays cpu info.  
cpuinfo.h  
cpuinfo.c - Gets CPU info and features.  
midr.h  
midr-a32.s - Get the MIDR register (gas).  
midr-a64.s  
midr.asm - (armasm64).  
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
hexstr-a64.s - (armasm64).  
hexstr-neon64.s - AArch64 NEON implementation (gas).  
hexstr-neon.asm - (armasm64).  
hexstr-a32.s - ARMv7-A assembly implementation.  
hexstr-neon32.s - ARMv7-A NEON implementation.  
hexstr-t32.s - ARMv7-A thumb implementation.  
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
arm64: a64cpuid, hexstr-a64c, hexstr-a64asm, hexstr-a64intrin, and hexstr-a64neon.  
arm32: a32cpuid, hexstr-a32c, hexstr-a32asm, hexstr-a32intrin, hexstr-a32neon, and hexstr-t32asm.  
make clean - Remove executable and build files.  
nmake /f hexstr-intel.mak - Create all executables for Windows x86_64.  
intel: cpuid.exe, hexstr-c.exe, hexstr-intrin.exe, hexstr-x64.exe, hexstr-sse.exe, hexstr-avx.exe, decstr-c.exe, decstr-intrin.exe, decstr-x64.exe, decstr-sse.exe, and decstr-avx.exe.  
nmake /f hexstr-arm.mak - Create all executables for Windows ARM.  
arm: hexstr-a64c.exe, hexstr-a64intrin.exe, hexstr-a64.exe, and hexstr-a64neon.exe.  
nmake /f hexstr-intel.mak clean - Remove executable and build files under Windows.  
nmake /f hexstr-arm.mak clean  

## Testing  
Intel based Mac.  
ARM based Mac.  
Intel based Windows PC.  
ARM based Windows PC (Virtualized on Mac).  
Intel based Linux PC.  
ARM based Linux PC (Virtualized on Mac).  
Raspberry Pi 64-bit (ARM64 Linux).  
Raspberry Pi 32-bit (ARM32 Linux).  

## Algorithms  
Previous experience has shown that different algorithms may be faster depending on the underlying hardware architecture. C based implementations use unrolled table-based lookup. Assembly based implementation have four options. Table lookup or computed hex digits. Copying individual digits to the output buffer or collecting digits in a register and only copying to the output buffer when the register is full. The assembly code has a pair of symbols defined to choose these algorithm options:  
use_table - Table lookup if defined, computed if undefined.  
use_bytes - Byte output if defined, full register output if undefined.  
Note that the value of the defined symbol does not matter. Conditional assembly is using .ifdef not .if. So, comment or uncomment the definitions as desired. During assembly the assembler will output messages indicating the current algorithm settings.  

## Examples  

What C implementation works best. The relative rankings of C, asm, simd intrinsics, or simd asm. Will all vary depending on system architecture and CPU generation.
```
$ make
Linux detected
Intel detected
...
Conditional Assembly: Lookup digits
Conditional Assembly: Output bytes
...
$ ./hexstr-c
GenuineIntel 11th Gen Intel(R) Core(TM) i5-1135G7 @ 2.40GHz Family 6 Model 140 4-Core 
SSE3 SSE4.2 AVX AVX2 GEN4 AVX512-F-CD AVX512-VL-DQ-BW AVX512-IFMA-VBMI 
Tests complete
FEDCBA9876543210
FEDCBA9876543210 0123456789ABCDEF
76543210 89ABCDEF
3210 CDEF
10 EF
0 F
iterations: 100,000,000
snprintf: 45.60 ns
u64:      4.76 ns
u32:      2.80 ns
u16:      1.69 ns
u8:       1.25 ns
u4:       1.24 ns
$ ./hexstr-x64
...
u64:      4.66 ns
u32:      2.58 ns
...
$ ./hexstr-intrin
...
u64:      1.57 ns
u32:      1.37 ns
...
$ ./hexstr-sse
...
u64:      1.33 ns
u32:      1.40 ns
...
$ ./hexstr-avx
...
u64:      1.24 ns
u32:      1.37 ns

% make
macOS detected
ARM detected
...
Conditional Assembly: Lookup digits
Conditional Assembly: Output bytes
...
% ./hexstr-a64c
Apple M4 Armv9 10-Core 
Performance:4 Efficiency:6 NEON SME SME2 
Tests complete
FEDCBA9876543210
FEDCBA9876543210 0123456789ABCDEF
76543210 89ABCDEF
3210 CDEF
10 EF
0 F
iterations: 100,000,000
snprintf: 28.58 ns
u64:      3.00 ns
u32:      1.80 ns
u16:      1.00 ns
u8:       0.73 ns
u4:       0.70 ns
% ./hexstr-a64asm
...
u64:      2.30 ns
u32:      1.23 ns
...
% ./hexstr-a64intrin
...
u64:      0.98 ns
u32:      0.98 ns
...
% ./hexstr-a64neon  
...
u64:      3.19 ns
u32:      3.19 ns
...

$ make
Linux detected
ARM32 detected
...
Conditional Assembly: Lookup digits
Conditional Assembly: Output bytes
...
$ ./hexstr-a32c
ARM Raspberry Pi 3 Model B Plus Rev 1.3 Cortex-A53 4-Core 
half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm crc32 
Tests complete
FEDCBA9876543210
FEDCBA9876543210 0123456789ABCDEF
76543210 89ABCDEF
3210 CDEF
10 EF
0 F
iterations: 100,000,000
snprintf: 651.11 ns
u64:      50.23 ns
u32:      35.17 ns
u16:      25.83 ns
u8:       16.50 ns
u4:       12.93 ns
$ ./hexstr-a32asm
...
u64:      65.82 ns
u32:      39.34 ns
...
$ ./hexstr-a32intrin
...
u64:      27.23 ns
u32:      21.47 ns
...
$ ./hexstr-a32neon
...
u64:      20.01 ns
u32:      18.60 ns
...
$ ./hexstr-t32asm
...
u64:      90.09 ns
u32:      58.39 ns
...
```

## To-do
Background task - reviewing and improving the code. Especially neon.  
