# hexstr-sse.s
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
# Some common code for the hex to string conversions.
# Arguments:
#     XMM0 Value
# Return:
#     XMM0 String
# Required:
#     SSE2

            .macro  toHexStr
            movq    xmm1, xmm0              # Set xmm1 to the LO nibbles
            psrlq   xmm0, 4                 # Set xmm0 to the HO nibbles
            pand    xmm1, lo[rip]
            pand    xmm0, lo[rip]

            punpcklbw xmm0, xmm1            # Interleave the HO and LO nibbles

            por     xmm0, ascii0[rip]       # Convert binary to ascii
            movdqa  xmm1, xmm0              # Determine which bytes should be A-F
            pcmpgtb xmm1, ascii9[rip]

            pand    xmm1, af[rip]           # Update bytes that should be A-F
            paddb   xmm0, xmm1
            .endm

#-----------------------------------------------------------------------------
# Convert value to zero terminated hex string.
# Arguments:
#     RDI  Buffer, assumed to be large enough for string and null terminator.
#     RSI  Value
# Return:
#     RAX  Buffer
# Required:
#      SSSE3

            .balign 16
u64ToHexStr:
_u64ToHexStr:
            bswap   rsi                     # Reverse bytes to match string
            movq    xmm0, rsi

            toHexStr

            movdqu  [rdi], xmm0             # Output the string
            mov     byte ptr [rdi + 16], 0  # Zero terminte string
            mov     rax, rdi                # Return original pointer
            ret

#-----------------------------------------------------------------------------

            .balign 16
u32ToHexStr:
_u32ToHexStr:
            bswap   esi                     # Reverse bytes to match string
            movd    xmm0, esi

            toHexStr

            movq    [rdi], xmm0             # Output the string
            mov     byte ptr [rdi + 8], 0   # Zero terminte string
            mov     rax, rdi                # Return original pointer
            ret

#-----------------------------------------------------------------------------

            .balign 16
u16ToHexStr:
_u16ToHexStr:
            movd    xmm0, esi               # Reverse bytes to match string
            pshufb  xmm0, swap16[rip]

            toHexStr

            movd    [rdi], xmm0             # Output the string
            mov     byte ptr [rdi + 4], 0   # Zero terminte string
            mov     rax, rdi                # Return original pointer
            ret

#-----------------------------------------------------------------------------
# For the smaller sizes its better to just use table lookup and byte output

            .balign 16
u8ToHexStr:
_u8ToHexStr:
            mov     rax, rdi                # Return original pointer

            lea     rdi, lookup[rip]        # Address of lookup table

            mov     ecx, esi                # Index into lookup table
            shr     ecx, 4
            and     rcx, 0xf
            mov     dl, [rdi + rcx]         # Hex char

            and     rsi, 0xf
            mov     dh, [rdi + rsi]

            mov     [rax], dx               # Output the string
            mov     byte ptr [rax + 2], 0   # Zero terminte string
            ret

#-----------------------------------------------------------------------------

            .balign 16
u4ToHexStr:
_u4ToHexStr:
            mov     rax, rdi                # Return original pointer

            lea     rdi, lookup[rip]        # Address of lookup table
            xor     edx, edx                # Register to build string in

            and     rsi, 0xf                # Index into lookup table
            mov     dl, [rdi + rsi]         # Hex char

            mov     [rax], dx               # Output string and zero terminaion
            ret

#-----------------------------------------------------------------------------

            .balign 16

ascii0:     .fill   16, 1, '0'
ascii9:     .fill   16, 1, '9'
af:         .fill   16, 1, 'A' - '0' - 10   # val+'0' to val+'A'
lo:         .fill   16, 1, 0x0F
swap16:     .byte   1,    0,    0x80, 0x80, 0x80, 0x80, 0x80, 0x80
            .byte   0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80

lookup:     .ascii  "0123456789ABCDEF"
