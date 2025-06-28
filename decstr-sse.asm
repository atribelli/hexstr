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

            lea         r8,   ten19qw       ; Integer divisors

            nextDigit64 0                   ; First 5 digits
            nextDigit64 1
            nextDigit64 2
            nextDigit64 3
            nextDigit64 4

            ; Switch to SSE code

            cvtsi2sd    xmm0, rdx           ; Convert to double
            shufpd      xmm0, xmm0, 0       ; Duplicate in lane 1
            movapd      xmm1, tend          ; Need 10 for mod calulation
            lea         r8,   ten14d - 5 * 8 ; Floating point divisors
                                            ; R8 is offset due to non zero index
            sseNextDigits2 5                ; Last 15 digits
            sseNextDigits2 7
            sseNextDigits2 9
            sseNextDigits2 11
            sseNextDigits2 13
            sseNextDigits2 15
            sseNextDigits2 17
            sseNextDigits1 19

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
            lea         r8,   ten9d         ; Floating point divisors

            sseNextDigits2 0                ; All 10 digits
            sseNextDigits2 2
            sseNextDigits2 4
            sseNextDigits2 6
            sseNextDigits2 8

            mov         byte ptr [rcx + 10], 0 ; Null terminator
            mov         rax,  rcx           ; Return original pointer
            and         rax,  not 1         ; Make sure sign included
            ret
u32ToDecStr endp

            end
