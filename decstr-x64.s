# decstr-x64.s
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

            .balign 16
u64ToDecStr:
_u64ToDecStr:
            mov     rdx, rsi                # Use div remainder register
            lea     r8, ten19u[rip]         # Divisors

            nextDigit   0
            nextDigit   1
            nextDigit   2
            nextDigit   3
            nextDigit   4
            nextDigit   5
            nextDigit   6
            nextDigit   7
            nextDigit   8
            nextDigit   9
            nextDigit   10
            nextDigit   11
            nextDigit   12
            nextDigit   13
            nextDigit   14
            nextDigit   15
            nextDigit   16
            nextDigit   17
            nextDigit   18

            add     dl, '0'                 # 20th digit is remainder
            mov     [rdi + 19], dl
            mov     byte ptr [rdi + 20], 0  # Null terminator
            mov     rax, rdi                # Return original pointer
            and     rax, ~1                 # Make sure sign included
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

            .balign 16
u32ToDecStr:
_u32ToDecStr:
            mov     edx, esi                # Use div remainder register
            lea     r8, ten9u[rip]          # Divisors

            nextDigit   0
            nextDigit   1
            nextDigit   2
            nextDigit   3
            nextDigit   4
            nextDigit   5
            nextDigit   6
            nextDigit   7
            nextDigit   8

            add     dl, '0'                 # 10th digit is remainder
            mov     [rdi + 9], dl
            mov     byte ptr [rdi + 10], 0  # Null terminator
            mov     rax, rdi                # Return original pointer
            and     rax, ~1                 # Make sure sign included
            ret
