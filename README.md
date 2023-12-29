# hexstr

Intel SSE and ARM NEON hexadecimal string creation.
Inspired by the books "The Art of 64-Bit Assembly" and "The Art of ARM Assembly" by Randall Hyde.  
https://nostarch.com/art-64-bit-assembly-volume-1  
https://nostarch.com/art-arm-assembly  

This is a testbed for experimenting with SIMD implementations. For comparison purposes there are ordinary C and assembly implementations.

## Files  
makefile - macOS and Linux based builds.  
hexstr.mak - Windows based builds.  
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
hexstr-x64.asm - x86-64 assembly implementation (masm).  
hexstr-sse.asm - SSE implementation (masm).  
hexstr-avx.asm - AVX implementation (masm).  

## Building  
make - Create C and intrinsics based code, hexstr-c hexstr-intrin.  
make intel - Create assembly and SSE code, hexstr-x64 hexstr-sse hexstr-avx.  
make arm64 - Create AArch64 assembly and NEON code, hexstr-a64 hexstr-neon64.  
make arm32 - Create ARMv7-A assembly and NEON code, hexstr-a32 hexstr-neon32.  
make clean - Remove executable and build files.  
nmake /f hexstr.mak - Create all executables for Windows.  
nmake /f hexstr.mak clean - Remove executable and build files under Windows.  

## Testing  
Intel based Mac.  
Windows PC.  
Raspberry Pi 64-bit.  
Raspberry Pi 32-bit.  

## Algorithms  
Previous experience has shown that different algorithms may be faster depending on the underlying hardware architecture. C based implementations use unrolled table-based lookup. Assembly based implementation have four options. Table lookup or computed hex digits. Copying individual digits to the output buffer or collecting digits in a register and only copying to the output buffer when the register is full. The assembly code has a pair of symbols defined to choose these algorithm options:  
use_table - Table lookup if defined, computed if undefined.  
use_bytes - Byte output if defined, full register output if undefined.  
Note that the value of the defined symbol does not matter. Conditional assembly is using .ifdef not .if. So, comment or uncomment the definitions as desired. During assembly the assembler will output messages indicating the current algorithm settings.  

## To-do
Background task - reviewing and improving the code.  

