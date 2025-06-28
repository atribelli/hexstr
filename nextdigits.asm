; nextdigits.asm
;
; An include file to share data and macros



;------------------------------------------------------------------------------

tables      segment readonly align(32) 'const'
            
; 20 digit integer divisor tables

            align   32
ten19qw     qword   10000000000000000000    ; 64-bit: 20 digits
            qword   1000000000000000000
            qword   100000000000000000
            qword   10000000000000000
            qword   1000000000000000
            qword   100000000000000
            qword   10000000000000
            qword   1000000000000
            qword   100000000000
            qword   10000000000
            qword   1000000000
            qword   1                       ; For disregarded lane

            align   32
ten8dw      dword   100000000               ; 32-bits: Last 9 digits
            dword   10000000
            dword   1000000
            dword   100000
            dword   10000
            dword   1000
            dword   100
            dword   10
            dword   1
            dword   1                       ; For 3 disregarded lanes
            dword   1
            dword   1

; 10 digit integer divisor table

            align   32
ten9dw      dword   1000000000              ; 32-bits: All 10 digits
            dword   100000000
            dword   10000000
            dword   1000000
            dword   100000
            dword   10000
            dword   1000
            dword   100
            dword   10
            dword   1
            dword   1                       ; For 2 disregarded lanes
            dword   1

; 15 digit floating point divisor table

            align   32
ten14d      real8   100000000000000.0       ; Limitted to 52-bit values
            real8   10000000000000.0
            real8   1000000000000.0
            real8   100000000000.0
            real8   10000000000.0
            real8   1000000000.0            ; 32-bit: 10 digits
            real8   100000000.0
            real8   10000000.0
            real8   1000000.0
            real8   100000.0
            real8   10000.0
            real8   1000.0
            real8   100.0
            real8   10.0
            real8   1.0
            real8   1.0                     ; For disregarded lane

; 10 digit floating point divisor table

            align   32
ten9d       real8   1000000000.0            ; 32-bit: 10 digits
            real8   100000000.0
            real8   10000000.0
            real8   1000000.0
            real8   100000.0                ; Limitted to 23-bit values
            real8   10000.0
            real8   1000.0
            real8   100.0
            real8   10.0
            real8   1.0
            real8   1.0                     ; For 2 disregarded lane2
            real8   1.0

; 6 digit floating point divisor table

            align   32
ten5s       real4   100000.0                ; Limitted to 23-bit values
            real4   10000.0
            real4   1000.0
            real4   100.0
            real4   10.0
            real4   1.0
            real4   1.0                     ; For 2 disregarded lanes
            real4   1.0

; Constant 10

            align   32
tend        real8   10.0, 10.0, 10.0, 10.0
tens        real4   10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0

; Constant ascii zero

            align   32
zerodw      dword   '0', '0', '0', '0', '0', '0', '0', '0'

            align   32
firstfourd  real8   1000000.0, 1000000.0, 1000000.0, 1000000.0

tables      ends



;------------------------------------------------------------------------------
; Macro with the code for calculating the quotient and remainder.
;
; nextDigit
; Arguments:
;     RCX  Buffer
;     RDX  Value
;     R8   Lookup table with divisors
;     i    Digit number
; Return:
;     RDX  Remainder

nextDigit64 macro   i
            mov     rax, rdx                ; Divide by current power of 10
            xor     rdx, rdx
            div     qword ptr [r8 + i * 8]
            add     al,  '0'                ; Convert to ascii digit
            mov     [rcx + i], al
            endm

nextDigit32 macro   i
            mov     eax, edx                ; Divide by current power of 10
            xor     edx, edx
            div     dword ptr [r8 + i * 4]
            add     al,  '0'                ; Convert to ascii digit
            mov     [rcx + i], al
            endm

; nextDigits
; Arguments:
;     RCX  Buffer
;     YMM0 Packed value
;     YMM1 Packed 10
;     YMM2 Packed ascii zero
;     R8   Lookup table of divisors
;     i    First digit number

; SSE implementation

sseNextDigits2 macro    i
            movapd      xmm3, [r8 + i * 8]  ; Divide by powers of 10
            movapd      xmm4, xmm0
            divpd       xmm4, xmm3
            roundpd     xmm4, xmm4, 3       ; Truncate for quotient
            movapd      xmm5, xmm4          ; Calculate mod 10
            divpd       xmm5, xmm1
            roundpd     xmm5, xmm5, 3
            mulpd       xmm5, xmm1
            subpd       xmm4, xmm5
            cvtsd2si    rax,  xmm4          ; Convert first modulus to int
            add         al,   '0'           ; Convert to ascii digit
            mov         [rcx + i], al
            shufpd      xmm4, xmm4, 1       ; Convert second modulus to int
            cvtsd2si    rax,  xmm4
            add         al,   '0'           ; Convert to ascii digit
            mov         [rcx + i + 1], al
            endm

sseNextDigits1 macro    i
            movapd      xmm3, [r8 + i * 8]  ; Divide by powers of 10
            movapd      xmm4, xmm0
            divpd       xmm4, xmm3
            roundpd     xmm4, xmm4, 3       ; Truncate for quotient
            movapd      xmm5, xmm4          ; Calculate mod 10
            divpd       xmm5, xmm1
            roundpd     xmm5, xmm5, 3
            mulpd       xmm5, xmm1
            subpd       xmm4, xmm5
            cvtsd2si    rax,  xmm4          ; Convert first modulus to int
            add         al,   '0'           ; Convert to ascii digit
            mov         [rcx + i], al
            endm

; AVX implementations

avxNextDigits4 macro    i
            vmovapd     ymm3, [r8 + i * 8]  ; Divide by current powers of 10
            vdivpd      ymm4, ymm0, ymm3
            vroundpd    ymm4, ymm4, 3       ; Truncate for quotient
            vdivpd      ymm5, ymm4, ymm1    ; Calculate mod 10
            vroundpd    ymm5, ymm5, 3
            vmulpd      ymm5, ymm5, ymm1
            vsubpd      ymm4, ymm4, ymm5
            vcvtpd2ps   xmm4, ymm4          ; Convert to float
            cvtps2dq    xmm4, xmm4          ; Convert to int
            paddd       xmm4, xmm2          ; Convert to ascii
            movd        eax,  xmm4          ; Extract first digit
            mov         [rcx + i], al
            pextrd      eax,  xmm4, 1       ; Extract second digit
            mov         [rcx + i + 1], al
            pextrd      eax,  xmm4, 2       ; Extract third digit
            mov         [rcx + i + 2], al
            pextrd      eax,  xmm4, 3       ; Extract fourth digit
            mov         [rcx + i + 3], al
            endm

avxNextDigits3 macro    i
            vmovapd     ymm3, [r8 + i * 8]  ; Divide by current powers of 10
            vdivpd      ymm4, ymm0, ymm3
            vroundpd    ymm4, ymm4, 3       ; Truncate for quotient
            vdivpd      ymm5, ymm4, ymm1    ; Calculate mod 10
            vroundpd    ymm5, ymm5, 3
            vmulpd      ymm5, ymm5, ymm1
            vsubpd      ymm4, ymm4, ymm5
            vcvtpd2ps   xmm4, ymm4          ; Convert to float
            cvtps2dq    xmm4, xmm4          ; Convert to int
            paddd       xmm4, xmm2          ; Convert to ascii
            movd        eax,  xmm4          ; Extract first digit
            mov         [rcx + i], al
            pextrd      eax,  xmm4, 1       ; Extract second digit
            mov         [rcx + i + 1], al
            pextrd      eax,  xmm4, 2       ; Extract third digit
            mov         [rcx + i + 2], al
            endm

avxNextDigits2 macro    i
            vmovapd     ymm3, [r8 + i * 8]  ; Divide by current powers of 10
            vdivpd      ymm4, ymm0, ymm3
            vroundpd    ymm4, ymm4, 3       ; Truncate for quotient
            vdivpd      ymm5, ymm4, ymm1    ; Calculate mod 10
            vroundpd    ymm5, ymm5, 3
            vmulpd      ymm5, ymm5, ymm1
            vsubpd      ymm4, ymm4, ymm5
            vcvtpd2ps   xmm4, ymm4          ; Convert to float
            cvtps2dq    xmm4, xmm4          ; Convert to int
            paddd       xmm4, xmm2          ; Convert to ascii
            movd        eax,  xmm4          ; Extract first digit
            mov         [rcx + i], al
            pextrd      eax,  xmm4, 1       ; Extract second digit
            mov         [rcx + i + 1], al
            endm

avxNextDigits6 macro    i
            vmovaps     ymm3, [r8 + i * 4]  ; Divide by current powers of 10
            vdivps      ymm4, ymm0, ymm3
            vroundps    ymm4, ymm4, 3       ; Truncate for quotient
            vdivps      ymm5, ymm4, ymm1    ; Calculate mod 10
            vroundps    ymm5, ymm5, 3
            vmulps      ymm5, ymm5, ymm1
            vsubps      ymm4, ymm4, ymm5
            vcvtps2dq   ymm4, ymm4          ; Convert to int
            vpaddd      ymm4, ymm4, ymm2    ; Convert to ascii
            movd        eax,  xmm4          ; Extract first digit
            mov         [rcx + i], al
            pextrd      eax,  xmm4, 1       ; Extract second digit
            mov         [rcx + i + 1], al
            pextrd      eax,  xmm4, 2       ; Extract third digit
            mov         [rcx + i + 2], al
            pextrd      eax,  xmm4, 3       ; Extract fourth digit
            mov         [rcx + i + 3], al
            vextractf128 xmm4, ymm4, 1      ; Extract fifth digit
            movd        eax,  xmm4
            mov         [rcx + i + 4], al
            pextrd      eax,  xmm4, 1       ; Extract sixth digit
            mov         [rcx + i + 5], al
            endm
