# hexstr-x64.s
#
# Convert values of various sizes to zero terminated hex strings.
#     u64ToHexStr   64-bit quad word
#     u32ToHexStr   32-bit double word
#     u16ToHexStr   16-bit word
#     u8ToHexStr    8-bit  byte
#     u4ToHexStr    4-bit  nibble

            .intel_syntax noprefix

            .ifdef  IsLinux
            .section .note.GNU-stack, "", %progbits
            .endif

            .text
            .balign 4
            .global u64ToHexStr, u32ToHexStr, u16ToHexStr
            .global u8ToHexStr, u4ToHexStr
            .global _u64ToHexStr, _u32ToHexStr, _u16ToHexStr
            .global _u8ToHexStr, _u4ToHexStr

#-----------------------------------------------------------------------------
# Comment/uncomment these symbol definition to control implementation
# of code.
#
# use_table allows table lookup rather than computation of chars.
# use_bytes allows individuals bytes to be output rather than collected
# in a register to be output as a word later.

            .set    use_table, 1
            .set    use_bytes, 1

            .ifdef  use_table
            .print  "Conditional Assembly: Lookup digits"
            .else
            .print  "Conditional Assembly: Compute digits"
            .endif
            .ifdef  use_bytes
            .print  "Conditional Assembly: Output bytes"
            .else
            .print  "Conditional Assembly: Output words"
            .endif

#-----------------------------------------------------------------------------
# Macros with the code for different implementations.
# Table vs compute, bytes vs words.
# What works best depends on the architecture, these allow us to easily test.
# Arguments:
#     RDI  Buffer if use_bytes defined
#     RAX  Current digits if use_bytes not defined
#     RCX  Value
#     RDX  Lookup table if use_table defined
#     i    Next position in buffer if use_bytes defined
# Return:
#     RDI  Buffer has new digit if use_bytes defined
#     RAX  Cuurrent digits shifted left if use_bytes not defined
#     AL   New digit

            # These macros are not used directly,
            # one of them will be used in nextDigit

            .macro  tableBytes, i
            mov     al, [rdx + rcx]         # Get the next digit
            mov     [rdi + \i], al          # Output the digit
            .endm

            .macro  tableWords
            shl     rax, 8                  # Shift the current digits
            mov     al, [rdx + rcx]         # Get the next digit
            .endm

            .macro  computeBytes, i
            mov     eax, ecx                # Convert value to 0-9
            add     eax, '0'
            add     ecx, 'A' - 10           # Convert value to A-F
            cmp     al, '9'                 # Verify 0-9
            cmovg   eax, ecx                # Switch to A-F
            mov     [rdi + \i], al          # Output the digit
            .endm

            .macro  computeWords
            shl     rax, 8                  # Shift the current digits
            mov     edx, ecx                # Convert value to A-F
            add     edx, 'A' - 10
            add     ecx, '0'                # Convert value to 0-9
            cmp     cl, '9'                 # Verify 0-9
            cmovg   ecx, edx                # Switch to A-F
            mov     al, cl                  # Output the digit
            .endm

            # The nextDigit macro will be used by the code below

            .macro  nextDigit, i
            .ifdef  use_table
                .ifdef  use_bytes
                    tableBytes \i
                .else
                    tableWords
                .endif
            .else
                .ifdef  use_bytes
                    computeBytes \i
                .else
                    computeWords
                .endif
            .endif
            .endm

#-----------------------------------------------------------------------------
# Convert value to zero terminated hex string.
# Arguments:
#     RDI  Buffer, assumed to be large enough for string and null terminator
#     RSI  Value
# Return:
#     RAX  Buffer
#
# We are going to start at the high order nibble
# and work down one at a time to the low order nibble.

            .balign 16
u64ToHexStr:
_u64ToHexStr:
            .ifdef  use_table
            lea     rdx, lookup[rip]        # Converts binary to char
            .endif

            mov     rcx, rsi                # Get the nibble to convert
            shr     rcx, 60
            nextDigit 0

            mov     rcx, rsi
            shr     rcx, 56
            and     ecx, 0xf
            nextDigit 1

            mov     rcx, rsi
            shr     rcx, 52
            and     ecx, 0xf
            nextDigit 2

            mov     rcx, rsi
            shr     rcx, 48
            and     ecx, 0xf
            nextDigit 3

            mov     rcx, rsi
            shr     rcx, 44
            and     ecx, 0xf
            nextDigit 4

            mov     rcx, rsi
            shr     rcx, 40
            and     ecx, 0xf
            nextDigit 5

            mov     rcx, rsi
            shr     rcx, 36
            and     ecx, 0xf
            nextDigit 6

            mov     rcx, rsi
            shr     rcx, 32
            and     ecx, 0xf
            nextDigit 7

            .ifndef use_bytes
            bswap   rax                     # Output HO digits
            mov     [rdi], rax
            .endif

            mov     ecx, esi
            shr     ecx, 28
            and     rcx, 0xf
            nextDigit 8

            mov     ecx, esi
            shr     ecx, 24
            and     rcx, 0xf
            nextDigit 9

            mov     ecx, esi
            shr     ecx, 20
            and     rcx, 0xf
            nextDigit 10

            mov     ecx, esi
            shr     ecx, 16
            and     rcx, 0xf
            nextDigit 11

            mov     ecx, esi
            shr     ecx, 12
            and     rcx, 0xf
            nextDigit 12

            mov     ecx, esi
            shr     ecx, 8
            and     rcx, 0xf
            nextDigit 13

            mov     ecx, esi
            shr     ecx, 4
            and     rcx, 0xf
            nextDigit 14

            mov     ecx, esi
            and     rcx, 0xf
            nextDigit 15

            .ifndef use_bytes
            bswap   rax                     # Output LO digits
            mov     [rdi + 8], rax
            .endif

            mov     byte ptr [rdi + 16], 0  # Zero terminte string
            mov     rax, rdi                # Return original pointer
            ret

#-----------------------------------------------------------------------------

            .balign 16
u32ToHexStr:
_u32ToHexStr:
            .ifdef  use_table
            lea     rdx, lookup[rip]        # Converts binary to char
            .endif

            mov     ecx, esi                # Get the nibble to convert
            shr     ecx, 28
            and     rcx, 0xf
            nextDigit 0

            mov     ecx, esi
            shr     ecx, 24
            and     rcx, 0xf
            nextDigit 1

            mov     ecx, esi
            shr     ecx, 20
            and     rcx, 0xf
            nextDigit 2

            mov     ecx, esi
            shr     ecx, 16
            and     rcx, 0xf
            nextDigit 3

            mov     ecx, esi
            shr     ecx, 12
            and     rcx, 0xf
            nextDigit 4

            mov     ecx, esi
            shr     ecx, 8
            and     rcx, 0xf
            nextDigit 5

            mov     ecx, esi
            shr     ecx, 4
            and     rcx, 0xf
            nextDigit 6

            mov     ecx, esi
            and     rcx, 0xf
            nextDigit 7

            .ifndef use_bytes
            bswap   rax                     # Output digits
            mov     [rdi], rax
            .endif

            mov     byte ptr [rdi + 8], 0   # Zero terminte string
            mov     rax, rdi                # Return original pointer
            ret

#-----------------------------------------------------------------------------

            .balign 16
u16ToHexStr:
_u16ToHexStr:
            .ifdef  use_table
            lea     rdx, lookup[rip]        # Converts binary to char
            .endif

            mov     ecx, esi                # Get the nibble to convert
            shr     ecx, 12
            and     rcx, 0xf
            nextDigit 0

            mov     ecx, esi
            shr     ecx, 8
            and     rcx, 0xf
            nextDigit 1

            mov     ecx, esi
            shr     ecx, 4
            and     rcx, 0xf
            nextDigit 2

            mov     ecx, esi
            and     rcx, 0xf
            nextDigit 3

            .ifndef use_bytes
            bswap   eax                     # Output digits
            mov     [rdi], eax
            .endif

            mov     byte ptr [rdi + 4], 0   # Zero terminte string
            mov     rax, rdi                # Return original pointer
            ret

#-----------------------------------------------------------------------------

            .balign 16
u8ToHexStr:
_u8ToHexStr:
            .ifdef  use_table
            lea     rdx, lookup[rip]        # Converts binary to char
            .endif

            mov     ecx, esi                # Get the nibble to convert
            shr     ecx, 4
            and     rcx, 0xf
            nextDigit 0

            mov     ecx, esi
            and     rcx, 0xf
            nextDigit 1

            .ifndef use_bytes
            mov     [rdi],     ah
            mov     [rdi + 1], al
            .endif

            mov     byte ptr [rdi + 2], 0   # Zero terminte string
            mov     rax, rdi                # Return original pointer
            ret

#-----------------------------------------------------------------------------

            .balign 16
u4ToHexStr:
_u4ToHexStr:
            .ifdef  use_table
            lea     rdx, lookup[rip]        # Converts binary to char
            .endif

            mov     ecx, esi                # Get the nibble to convert
            and     rcx, 0xf
            nextDigit 0

            .ifndef use_bytes
            mov     [rdi], al
            .endif

            mov     byte ptr [rdi + 1], 0   # Zero terminte string
            mov     rax, rdi                # Return original pointer
            ret

#-----------------------------------------------------------------------------

            .balign 16

            .ifdef  use_table
lookup:     .ascii  "0123456789ABCDEF"
            .endif
