; decstr-x64.asm
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

            align   16
u64ToDecStr proc
            lea     r8, ten19qw             ; Divisors

            nextDigit64 0                   ; First 11 digits
            nextDigit64 1
            nextDigit64 2
            nextDigit64 3
            nextDigit64 4
            nextDigit64 5
            nextDigit64 6
            nextDigit64 7
            nextDigit64 8
            nextDigit64 9
            nextDigit64 10

            lea     r8, ten8dw - 11 * 4     ; Divisors, offset by index

            nextDigit32 11                  ; Next 8 digits
            nextDigit32 12
            nextDigit32 13
            nextDigit32 14
            nextDigit32 15
            nextDigit32 16
            nextDigit32 17
            nextDigit32 18

            add     dl, '0'                 ; 20th digit is remainder
            mov     [rcx + 19], dl
            mov     byte ptr [rcx + 20], 0  ; Null terminator
            mov     rax, rcx                ; Return original pointer
            and     rax, not 1              ; Make sure sign included
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

            align   16
u32ToDecStr proc
            mov     edx,  edx               ; Clear upper dword
            lea     r8, ten9dw              ; Divisors

            nextDigit32 0
            nextDigit32 1
            nextDigit32 2
            nextDigit32 3
            nextDigit32 4
            nextDigit32 5
            nextDigit32 6
            nextDigit32 7
            nextDigit32 8

            add     dl, '0'                 ; 10th digit is remainder
            mov     [rcx + 9], dl
            mov     byte ptr [rcx + 10], 0  ; Null terminator
            mov     rax, rcx                ; Return original pointer
            and     rax, not 1              ; Make sure sign included
            ret
u32ToDecStr endp

            end
