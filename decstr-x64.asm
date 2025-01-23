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
;     RCX  Buffer, assumed to be large enough for string and null terminator
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
            lea     r8, ten19u              ; Divisors

            nextDigit 0
            nextDigit 1
            nextDigit 2
            nextDigit 3
            nextDigit 4
            nextDigit 5
            nextDigit 6
            nextDigit 7
            nextDigit 8
            nextDigit 9
            nextDigit 10
            nextDigit 11
            nextDigit 12
            nextDigit 13
            nextDigit 14
            nextDigit 15
            nextDigit 16
            nextDigit 17
            nextDigit 18

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
            lea     r8, ten9u               ; Divisors

            nextDigit 0
            nextDigit 1
            nextDigit 2
            nextDigit 3
            nextDigit 4
            nextDigit 5
            nextDigit 6
            nextDigit 7
            nextDigit 8

            add     dl, '0'                 ; 10th digit is remainder
            mov     [rcx + 9], dl
            mov     byte ptr [rcx + 10], 0  ; Null terminator
            mov     rax, rcx                ; Return original pointer
            and     rax, not 1              ; Make sure sign included
            ret
u32ToDecStr endp

            end
