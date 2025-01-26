# decstr-avx.s
#
# Convert values of various sizes to zero terminated decimal strings.
#     u64ToDecStr   64-bit unsigned quad word
#     s64ToDecStr   64-bit signed quad word
#     u32ToDecStr   32-bit unsigned quad word
#     s32ToDecStr   32-bit signed quad word

            .intel_syntax noprefix

            .ifdef  IsLinux
            .section .note.GNU-stack, "", %progbits
            .endif



#-----------------------------------------------------------------------------

            .include    "nextdigits.s"      # Macros and tables



#-----------------------------------------------------------------------------

            .text
            .balign     4
            .global     u64ToDecStr, s64ToDecStr, u32ToDecStr, s32ToDecStr
            .global     _u64ToDecStr, _s64ToDecStr, _u32ToDecStr, _s32ToDecStr



#-----------------------------------------------------------------------------
# Convert value to zero terminated decimal string.
# Arguments:
#     RDI  Buffer, assumed to be large enough for string and null terminator,
#          and assumed to be aligned to an even address
#     RSI  Value
# Return:
#     RAX  Buffer

            .balign 16
s64ToDecStr:
_s64ToDecStr:
            cmp     rsi, 0                  # Jump if not negative to
            jge     _u64ToDecStr            #   unsigned code
            neg     rsi                     # Absolute value
            mov     byte ptr [rdi], '-'     # Output sign
            inc     rdi
            jmp     _u64ToDecStr            # Continue using unsigned code

            .balign     16
u64ToDecStr:
_u64ToDecStr:
            # There is no integer divide for AVX,
            # only floating point divide.
            # Use x86 code for values that are
            # too large to fit in a double without rounding.

            mov         rdx,  rsi           # Use div remainder register
            lea         r8,   ten19qw[rip]  # Integer divisors

            nextDigit64 0                   # First 5 digits
            nextDigit64 1
            nextDigit64 2
            nextDigit64 3
            nextDigit64 4

            # Switch to AVX code

            cvtsi2sd    xmm0, rdx           # Convert to double
            vbroadcastsd ymm0, xmm0         # Duplicate in lanes 1, 2, 3
            vmovapd     ymm1, tend[rip]     # Need 10 for mod calculation
            vmovdqa     ymm2, zerodw[rip]   # Need ascii zero
            lea         r8,   ten14d[rip - 5 * 8] # Floating point divisors,
                                            # R8 is offset due to non zero index
            avxNextDigits4 5                # Last 15 digits
            avxNextDigits4 9
            avxNextDigits4 13
            avxNextDigits3 17

            mov         byte ptr [rdi + 20], 0 # Null terminator
            mov         rax,  rdi           # Return original pointer
            and         rax,  ~1            # Make sure sign included
            ret



#-----------------------------------------------------------------------------

            .balign 16
s32ToDecStr:
_s32ToDecStr:
            cmp     esi, 0                  # Jump if not negative to
            jge     _u32ToDecStr            #   unsigned code
            neg     esi                     # Absolute value
            mov     byte ptr [rdi], '-'     # Output sign
            inc     rdi
            jmp     _u32ToDecStr            # Continue using unsigned code

            .balign     16
u32ToDecStr:
_u32ToDecStr:
            mov         esi,  esi           # Clear upper dword
            cvtsi2sd    xmm0, rsi           # Convert to double
            vbroadcastsd ymm0, xmm0         # Duplicate in lanes 1, 2, 3
            vmovapd     ymm1, tend[rip]     # Need 10 for mod calculation
            vmovdqa     ymm2, zerodw[rip]   # Need ascii zero
            lea         r8,   ten9d[rip]    # Floating point divisors

            avxNextDigits4 0                # First 4 digits

            vmovsd      xmm3, firstfourd[rip] # Remove first four digits
            vdivsd      xmm4, xmm0, xmm3
            roundsd     xmm4, xmm4, 3
            vmulsd      xmm4, xmm4, xmm3
            vsubsd      xmm0, xmm0, xmm4
            cvtsd2ss    xmm0, xmm0          # Switch to floats
            vbroadcastss ymm0, xmm0         # Duplicate in lanes 1 ... 7

            vmovaps     ymm1, tens[rip]
            lea         r8,   ten5s[rip - 4 * 4]

            avxNextDigits6 4                # Last 6 digits
 
            mov         byte ptr [rdi + 10], 0 # Null terminator
            mov         rax,  rdi           # Return original pointer
            and         rax,  ~1            # Make sure sign included
            ret
