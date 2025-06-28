# nextdigits.s
#
# An include file to share macross and data



#-----------------------------------------------------------------------------
# Macros with the code for calculating quotient and remainder.
#
# nextDigit
# Arguments:
#     RDI  Buffer
#     RDX  Value
#     R8   Lookup table of divisors
#     i    Digit number
# Return:
#     RDX  Remainder

            .macro  nextDigit64, i
            mov     rax, rdx                # Divide by current power of 10
            xor     rdx, rdx
            div     qword ptr [r8 + \i * 8]
            add     al,  '0'                # Convert to ascii digit
            mov     [rdi + \i], al
            .endm

            .macro  nextDigit32, i
            mov     eax, edx                # Divide by current power of 10
            xor     edx, edx
            div     dword ptr [r8 + \i * 4]
            add     al,  '0'                # Convert to ascii digit
            mov     [rdi + \i], al
            .endm

# nextDigits
# Arguments:
#     RDI  Buffer
#     YMM0 Packed value
#     YMM1 Packed 10
#     YMM2 Packed ascii zero
#     R8   Lookup table of divisors
#     i    First digit number

            # SSE implementation

            .macro      sseNextDigits2, i
            movapd      xmm3, [r8 + \i * 8] # Divide by powers of 10
            movapd      xmm4, xmm0
            divpd       xmm4, xmm3
            roundpd     xmm4, xmm4, 3       # Truncate for quotient
            movapd      xmm5, xmm4          # Calculate mod 10
            divpd       xmm5, xmm1
            roundpd     xmm5, xmm5, 3
            mulpd       xmm5, xmm1
            subpd       xmm4, xmm5
            cvtsd2si    rax,  xmm4          # Convert first modulus to int
            add         al,   '0'           # Convert to ascii digit
            mov         [rdi + \i], al
            shufpd      xmm4, xmm4, 1       # Convert second modulus to int
            cvtsd2si    rax,  xmm4
            add         al,   '0'           # Convert to ascii digit
            mov         [rdi + \i + 1], al
            .endm

            .macro      sseNextDigits1, i
            movapd      xmm3, [r8 + \i * 8] # Divide by powers of 10
            movapd      xmm4, xmm0
            divpd       xmm4, xmm3
            roundpd     xmm4, xmm4, 3       # Truncate for quotient
            movapd      xmm5, xmm4          # Calculate mod 10
            divpd       xmm5, xmm1
            roundpd     xmm5, xmm5, 3
            mulpd       xmm5, xmm1
            subpd       xmm4, xmm5
            cvtsd2si    rax,  xmm4          # Convert first modulus to int
            add         al,   '0'           # Convert to ascii digit
            mov         [rdi + \i], al
            .endm

            # AVX implementations

            .macro      avxNextDigits4, i
            vmovapd     ymm3, [r8 + \i * 8] # Divide by current powers of 10
            vdivpd      ymm4, ymm0, ymm3
            vroundpd    ymm4, ymm4, 3       # Truncate for quotient
            vdivpd      ymm5, ymm4, ymm1    # Calculate mod 10
            vroundpd    ymm5, ymm5, 3
            vmulpd      ymm5, ymm5, ymm1
            vsubpd      ymm4, ymm4, ymm5
            vcvtpd2ps   xmm4, ymm4          # Convert to float
            cvtps2dq    xmm4, xmm4          # Convert to int
            paddd       xmm4, xmm2          # Convert to ascii
            movd        eax,  xmm4          # Extract first digit
            mov         [rdi + \i], al
            pextrd      eax,  xmm4, 1       # Extract second digit
            mov         [rdi + \i + 1], al
            pextrd      eax,  xmm4, 2       # Extract third digit
            mov         [rdi + \i + 2], al
            pextrd      eax,  xmm4, 3       # Extract fourth digit
            mov         [rdi + \i + 3], al
            .endm

            .macro      avxNextDigits3, i
            vmovapd     ymm3, [r8 + \i * 8] # Divide by current powers of 10
            vdivpd      ymm4, ymm0, ymm3
            vroundpd    ymm4, ymm4, 3       # Truncate for quotient
            vdivpd      ymm5, ymm4, ymm1    # Calculate mod 10
            vroundpd    ymm5, ymm5, 3
            vmulpd      ymm5, ymm5, ymm1
            vsubpd      ymm4, ymm4, ymm5
            vcvtpd2ps   xmm4, ymm4          # Convert to float
            cvtps2dq    xmm4, xmm4          # Convert to int
            paddd       xmm4, xmm2          # Convert to ascii
            movd        eax,  xmm4          # Extract first digit
            mov         [rdi + \i], al
            pextrd      eax,  xmm4, 1       # Extract second digit
            mov         [rdi + \i + 1], al
            pextrd      eax,  xmm4, 2       # Extract third digit
            mov         [rdi + \i + 2], al
            .endm

            .macro      avxNextDigits2, i
            vmovapd     ymm3, [r8 + \i * 8] # Divide by current powers of 10
            vdivpd      ymm4, ymm0, ymm3
            vroundpd    ymm4, ymm4, 3       # Truncate for quotient
            vdivpd      ymm5, ymm4, ymm1    # Calculate mod 10
            vroundpd    ymm5, ymm5, 3
            vmulpd      ymm5, ymm5, ymm1
            vsubpd      ymm4, ymm4, ymm5
            vcvtpd2ps   xmm4, ymm4          # Convert to float
            cvtps2dq    xmm4, xmm4          # Convert to int
            paddd       xmm4, xmm2          # Convert to ascii
            movd        eax,  xmm4          # Extract first digit
            mov         [rdi + \i], al
            pextrd      eax,  xmm4, 1       # Extract second digit
            mov         [rdi + \i + 1], al
            .endm

            .macro      avxNextDigits6, i
            vmovaps     ymm3, [r8 + \i * 4] # Divide by current powers of 10
            vdivps      ymm4, ymm0, ymm3
            vroundps    ymm4, ymm4, 3       # Truncate for quotient
            vdivps      ymm5, ymm4, ymm1    # Calculate mod 10
            vroundps    ymm5, ymm5, 3
            vmulps      ymm5, ymm5, ymm1
            vsubps      ymm4, ymm4, ymm5
            vcvtps2dq   ymm4, ymm4          # Convert to int
            vpaddd      ymm4, ymm4, ymm2    # Convert to ascii
            movd        eax,  xmm4          # Extract first digit
            mov         [rdi + \i], al
            pextrd      eax,  xmm4, 1       # Extract second digit
            mov         [rdi + \i + 1], al
            pextrd      eax,  xmm4, 2       # Extract third digit
            mov         [rdi + \i + 2], al
            pextrd      eax,  xmm4, 3       # Extract fourth digit
            mov         [rdi + \i + 3], al
            vextractf128 xmm4, ymm4, 1      # Extract fifth digit
            movd        eax,  xmm4
            mov         [rdi + \i + 4], al
            pextrd      eax,  xmm4, 1       # Extract sixth digit
            mov         [rdi + \i + 5], al
            .endm



#-----------------------------------------------------------------------------

            .text

# 20 digit integer divisor tables

            .balign 32
ten19qw:    .quad   10000000000000000000    # 64-bits: First 11 digits
            .quad   1000000000000000000
            .quad   100000000000000000
            .quad   10000000000000000
            .quad   1000000000000000
            .quad   100000000000000
            .quad   10000000000000
            .quad   1000000000000
            .quad   100000000000
            .quad   10000000000
            .quad   1000000000
            .quad   1                       # For disregarded lane

            .balign 32
ten8dw:     .long   100000000               # 32-bits: Last 9 digits
            .long   10000000
            .long   1000000
            .long   100000
            .long   10000
            .long   1000
            .long   100
            .long   10
            .long   1
            .long   1                       # For 3 disregarded lanes
            .long   1
            .long   1

# 10 digit integer divisor table

            .balign 32
ten9dw:     .long   1000000000              # 32-bits: All 10 digits
            .long   100000000
            .long   10000000
            .long   1000000
            .long   100000
            .long   10000
            .long   1000
            .long   100
            .long   10
            .long   1
            .long   1                       # For 2 disregarded lanes
            .long   1

# 15 digit floating point divisor table

            .balign 32
ten14d:     .double 100000000000000.0       # Limitted to 52-bit values
            .double 10000000000000.0
            .double 1000000000000.0
            .double 100000000000.0
            .double 10000000000.0
            .double 1000000000.0            # 32-bit: 10 digits
            .double 100000000.0
            .double 10000000.0
            .double 1000000.0
            .double 100000.0
            .double 10000.0
            .double 1000.0
            .double 100.0
            .double 10.0
            .double 1.0
            .double 1.0                     # For disregarded lane

# 10 digit floating point divisor table

            .balign 32
ten9d:      .double 1000000000.0            # 32-bit: 10 digits
            .double 100000000.0
            .double 10000000.0
            .double 1000000.0
            .double 100000.0                # Limitted to 23-bit values
            .double 10000.0
            .double 1000.0
            .double 100.0
            .double 10.0
            .double 1.0
            .double 1.0                     # For 2 disregarded lane2
            .double 1.0

# 6 digit floating point divisor table

            .balign 32
ten5s:      .float  100000.0                # Limitted to 23-bit values
            .float  10000.0
            .float  1000.0
            .float  100.0
            .float  10.0
            .float  1.0
            .float  1.0                     # For 2 disregarded lanes
            .float  1.0

# Constant 10

            .balign 32
tend:       .double 10.0, 10.0, 10.0, 10.0
tens:       .float  10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0

# Constant ascii zero

            .balign 32
zerodw:     .long   '0', '0', '0', '0', '0', '0', '0', '0'

            .balign 32
firstfourd: .double 1000000.0, 1000000.0, 1000000.0, 1000000.0

