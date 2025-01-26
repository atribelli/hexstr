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
;     RCX  Buffer, assumed to be large enough for string and null terminator,
;          and assumed to be aligned to an even address
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

            lea         r8,   ten19qw       ; Integer divisors

            nextDigit64 0                   ; First 5 digits
            nextDigit64 1
            nextDigit64 2
            nextDigit64 3
            nextDigit64 4

            ; Switch to AVX code

            cvtsi2sd    xmm0, rdx           ; Convert to double
            vbroadcastsd ymm0, xmm0         ; Duplicate in lanes 1, 2, 3
            vmovapd     ymm1, tend          ; Need 10 for mod calulation
            vmovdqa     ymm2, ymmword ptr zerodw ; Need ascii zero
            lea         r8,   ten14d - 5 * 8 ; Floating point divisors
                                            ; R8 is offset for non zero index
            avxNextDigits4 5                ; Last 15 digits
            avxNextDigits4 9
            avxNextDigits4 13
            avxNextDigits3 17

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
            vmovdqa     ymm2, ymmword ptr zerodw ; Need ascii zero
            lea         r8,   ten9d         ; Floating point divisors

            avxNextDigits4 0                ; First 4 digits

            vmovsd      xmm3, firstfourd    ; Remove first four digits
            vdivsd      xmm4, xmm0, xmm3
            roundsd     xmm4, xmm4, 3
            vmulsd      xmm4, xmm4, xmm3
            vsubsd      xmm0, xmm0, xmm4
            cvtsd2ss    xmm0, xmm0          ; Switch to floats
            vbroadcastss ymm0, xmm0         ; Duplicate in lanes 1 ... 7

            vmovaps     ymm1, tens
            lea         r8,   ten5s - 4 * 4

            avxNextDigits6 4                ; Last 6 digits

            mov         byte ptr [rcx + 10], 0 ; Null terminator
            mov         rax,  rcx           ; Return original pointer
            and         rax,  not 1         ; Make sure sign included
            ret
u32ToDecStr endp

            end
