; nextdigits.asm
;
; An include file to share data and macros



;------------------------------------------------------------------------------

tables      segment readonly align(32) 'const'
            
; 20 and 10 digit integer divisor table

            align   32
ten19u      qword   10000000000000000000    ; 64-bit: 20 digits
            qword   1000000000000000000
            qword   100000000000000000
            qword   10000000000000000
            qword   1000000000000000
            qword   100000000000000
            qword   10000000000000
            qword   1000000000000
            qword   100000000000
            qword   10000000000
ten9u       qword   1000000000              ; 32-bit: 10 digits
            qword   100000000
            qword   10000000
            qword   1000000
            qword   100000
            qword   10000
            qword   1000
            qword   100
            qword   10
            qword   1

; 16 digit floating point divisor table

            align   32
ten13fp     real8   10000000000000.0        ; Limitted to 51-bit values
            real8   1000000000000.0
            real8   100000000000.0
            real8   10000000000.0
ten9fp      real8   1000000000.0
            real8   100000000.0
            real8   10000000.0
            real8   1000000.0
            real8   100000.0
            real8   10000.0
            real8   1000.0
            real8   100.0
            real8   10.0
            real8   1.0
            real8   1.0                     ; For 2 disregarded lanes
            real8   1.0

; 12 digit floating point divisor table.
; Needed 12 digit entry with an aligned address.

            align   32
ten11fp     real8   100000000000.0          ; Limitted to 51-bit values
            real8   10000000000.0
            real8   1000000000.0
            real8   100000000.0
            real8   10000000.0
            real8   1000000.0
            real8   100000.0
            real8   10000.0
            real8   1000.0
            real8   100.0
            real8   10.0
            real8   1.0

; 6 digit floating point divisor table.
; Needed float rather than double.

            align   32
ten5fp      real4   100000.0                ; 32-bit: 6 digits
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

            align   32
tenf        real4   10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0

; Constant ascii zero

            align   32
zero        dword   '0', '0', '0', '0', '0', '0', '0', '0'

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

nextDigit   macro   i
            mov     rax, rdx                ; Divide by current power of 10
            xor     rdx, rdx
            div     qword ptr [r8 + i * 8]
            add     al, '0'                 ; Convert to ascii digit
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

; 2 doubles
nextDigits2 macro       i
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

; AVX implementations

; 4 doubles
nextDigits4 macro       i
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

; 6 floats
nextDigits6 macro       i
            vmovaps     ymm3, [r8 + i * 4] ; Divide by current powers of 10
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
