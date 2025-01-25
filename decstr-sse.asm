; decstr-sse.asm
;
; Convert values of various sizes to zero terminated decimal strings.
;     u64ToDecStr   64-bit unsigned quad word
;     s64ToDecStr   64-bit signed quad word
;     u32ToDecStr   32-bit unsigned quad word
;     s32ToDecStr   32-bit signed quad word



;------------------------------------------------------------------------------

            include nextdigits.asm



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
            ; There is no integer divide for SSE,
            ; only floating point divide.
            ; Use x86 code for values that are
            ; too large to fit in a double.

            lea         r8,   ten19u        ; Integer divisors

            nextDigit   0                   ; First 6 digits
            nextDigit   1
            nextDigit   2
            nextDigit   3
            nextDigit   4
            nextDigit   5

            ; Switch to SSE code

            cvtsi2sd    xmm0, rdx           ; Convert to double
            shufpd      xmm0, xmm0, 0       ; Duplicate in lane 1
            movapd      xmm1, tend          ; Need 10 for mod calulation
            lea         r8,   ten13fp - 6 * 8 ; Floating point divisors
                                            ; R8 is offset due to non zero index
            nextDigits2 6                   ; Remaining 14 digits
            nextDigits2 8
            nextDigits2 10
            nextDigits2 12
            nextDigits2 14
            nextDigits2 16
            nextDigits2 18

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
            shufpd      xmm0, xmm0, 0       ; Duplicate in lane 1
            movapd      xmm1, tend          ; Need 10 for mod calulation
            lea         r8,   ten9fp        ; Floating point divisors

            nextDigits2 0
            nextDigits2 2
            nextDigits2 4
            nextDigits2 6
            nextDigits2 8

            mov         byte ptr [rcx + 10], 0 ; Null terminator
            mov         rax,  rcx           ; Return original pointer
            and         rax,  not 1         ; Make sure sign included
            ret
u32ToDecStr endp

            end
