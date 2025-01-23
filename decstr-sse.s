# decstr-sse.s
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

            .include    "nextdigits.s"



#-----------------------------------------------------------------------------

            .text
            .balign     4
            .global     u64ToDecStr, s64ToDecStr, u32ToDecStr, s32ToDecStr
            .global     _u64ToDecStr, _s64ToDecStr, _u32ToDecStr, _s32ToDecStr



#-----------------------------------------------------------------------------
# Convert value to zero terminated decimal string.
# Arguments:
#     RDI  Buffer, assumed to be large enough for string and null terminator
#          and assumped to be alighed to an even address
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
            # There is no integer divide for SSE,
            # only floating point divide.
            # Use x86 code for values that are
            # too large to fit in a double.

            mov         rdx,  rsi           # Use div remainder register
            lea         r8,   ten19u[rip]   # Integer divisors

            nextDigit   0                   # First 6 digits
            nextDigit   1
            nextDigit   2
            nextDigit   3
            nextDigit   4
            nextDigit   5

            # Switch to SSE code

            cvtsi2sd    xmm0, rdx           # Convert to double
            movddup     xmm0, xmm0          # Duplicate in lane 1
            movddup     xmm1, tend[rip]     # Need 10 for mod calulation
            lea         r8,   ten13fp[rip - 6 * 8] # Floating point divisors,
                                            # R8 is offset due to non zero index
            nextDigits2 6                   # Remaining 14 digits
            nextDigits2 8
            nextDigits2 10
            nextDigits2 12
            nextDigits2 14
            nextDigits2 16
            nextDigits2 18

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
            movddup     xmm0, xmm0          # Duplicate in lane 1
            movddup     xmm1, tend[rip]     # Need 10 for mod calulation
            lea         r8,   ten9fp[rip]   # Floating point divisors

            nextDigits2 0
            nextDigits2 2
            nextDigits2 4
            nextDigits2 6
            nextDigits2 8

            mov         byte ptr [rdi + 10], 0 # Null terminator
            mov         rax,  rdi           # Return original pointer
            and         rax,  ~1            # Make sure sign included
            ret
