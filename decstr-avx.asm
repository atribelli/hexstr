; decstr-avx.asm
;
; Convert values of various sizes to zero terminated decimal strings.
;     u64ToDecStr   64-bit unsigned quad word
;     s64ToDecStr   64-bit signed quad word
;     u32ToDecStr   32-bit unsigned quad word
;     s32ToDecStr   32-bit signed quad word



;------------------------------------------------------------------------------

            include nextdigits.asm      ; Macros and tables



;------------------------------------------------------------------------------

            .code
            align   4
            public  u64ToDecStr, u32ToDecStr
            public  s64ToDecStr, s32ToDecStr



;------------------------------------------------------------------------------
; Convert value to zero terminated decimal string.
; Arguments:
;     RCX  Buffer, assumed to be large enough for string and null terminator
;          and assumped to be alighed to an even address
;     RDX  Value
; Return:
;     RAX  Buffer

            align   16
s64ToDecStr proc
            cmp     rdx, 0                  ; Jump if not negative to
            jge     u64ToDecStr             ;   unsigned code
            neg     rdx                     ; Absolute value
            mov     byte ptr [rcx], '-'     ; Output sign
            inc     rcx
            jmp     u64ToDecStr             ; Continue using unsigned code
s64ToDecStr endp

            align       16
u64ToDecStr proc
            ; There is no integer divide for AVX,
            ; only floating point divide.
            ; Use x86 code for values that are
            ; too large to fit in a double without rounding.

            lea         r8,   ten19u        ; Integer divisors

            nextDigit   0                   ; First 6 digits
            nextDigit   1
            nextDigit   2
            nextDigit   3
            nextDigit   4
            nextDigit   5

            ; Switch to AVX code

            cvtsi2sd    xmm0, rdx           ; Convert to double
            vbroadcastsd ymm0, xmm0         ; Duplicate in lanes 1, 2, 3
            vmovapd     ymm1, tend          ; Need 10 for mod calulation
            vmovdqa     ymm2, ymmword ptr zero ; Need ascii zero
            lea         r8,   ten13fp - 6 * 8 ; Floating point divisors
                                            ; R8 is offset for non zero index
            nextDigits2 6                   ; Next 2 digits

            lea         r8,   ten11fp - 8 * 8 ; Floating point divisors
                                            ; R8 is offset for non zero index
            nextDigits4 8                   ; Remaining 12 digits
            nextDigits4 12
            nextDigits4 16

            mov         byte ptr [rcx + 20], 0 ; Null terminator
            mov         rax,  rcx           ; Return original pointer
            and         rax,  not 1         ; Make sure sign included
            ret
u64ToDecStr endp



;------------------------------------------------------------------------------

            align   16
s32ToDecStr proc
            cmp     edx, 0                  ; Jump if not negative to
            jge     u32ToDecStr             ;   unsigned code
            neg     edx                     ; Absolute value
            mov     byte ptr [rcx], '-'     ; Output sign
            inc     rcx
            jmp     u32ToDecStr             ; Continue using unsigned code
s32ToDecStr endp

            align       16
u32ToDecStr proc
            mov         edx,  edx           ; Clear upper dword
            cvtsi2sd    xmm0, rdx           ; Convert to double
            vbroadcastsd ymm0, xmm0         ; Duplicate in lanes 1, 2, 3
            vmovapd     ymm1, tend          ; Need 10 for mod calulation
            vmovdqa     ymm2, ymmword ptr zero ; Need ascii zero
            
            lea         r8,   ten9fp        ; Double divisors
            nextDigits4 0                   ; First 4 digits
            
            mov         eax,  1000000       ; Remove the first four digits
            cvtsi2sd    xmm1, eax           ;   of the original value
            vdivsd      xmm3, xmm0, xmm1    ;   so we can continue
            roundsd     xmm3, xmm3, 3       ;   calculations using floats
            vmulsd      xmm3, xmm3, xmm1
            vsubsd      xmm0, xmm0, xmm3
            cvtsd2ss    xmm0, xmm0
            vbroadcastss ymm0, xmm0         ; Duplicate in lanes 1 ... 7

            vmovaps     ymm1, tenf     ; Switch to floats
            lea         r8,   ten5fp - 4 * 4
            nextDigits6 4                   ; Remaining 6 digits

            mov         byte ptr [rcx + 10], 0 ; Null terminator
            mov         rax,  rcx           ; Return original pointer
            and         rax,  not 1         ; Make sure sign included
            ret
u32ToDecStr endp

            end
