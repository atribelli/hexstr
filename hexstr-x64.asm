; hexstr-x64.asm
;
; Convert values of various sizes to zero terminated hex strings.
;     u64ToHexStr   64-bit quad word
;     u32ToHexStr   32-bit double word
;     u16ToHexStr   16-bit word
;     u8ToHexStr    8-bit  byte
;     u4ToHexStr    4-bit  nibble

;------------------------------------------------------------------------------

            .const

;------------------------------------------------------------------------------
; Comment/uncomment these symbol definition to control implementation
; of code.
;
; use_table allows table lookup rather than computation of chars.
; use_bytes allows individuals bytes to be output rather than collected
; in a register to be output as a word later.

use_table   dword   1
use_bytes   dword   1

            ifdef   use_table
            echo    Conditional Assembly: Lookup digits
            else
            echo    Conditional Assembly: Compute digits
            endif
            ifdef   use_bytes
            echo    Conditional Assembly: Output bytes
            else
            echo    Conditional Assembly: Output words
            endif

;------------------------------------------------------------------------------

            .code
            align   4
            public  u64ToHexStr, u32ToHexStr, u16ToHexStr
            public  u8ToHexStr, u4ToHexStr

;------------------------------------------------------------------------------
; Macros with the code for different implementations.
; Table vs compute, bytes vs words.
; What works best depends on the architecture, these allow us to easily test.
; Arguments:
;     RCX  Buffer if use_bytes defined
;     RAX  Current digits if use_bytes not defined
;     R9   Value
;     R8   Lookup table if use_table defined
;     i    Next position in buffer if use_bytes defined
; Return:
;     RCX  Buffer has new digit if use_bytes defined
;     RAX  Cuurrent digits shifted left if use_bytes not defined
;     AL   New digit

; These macros are not used directly,
; one of them will be used in nextDigit

tableBytes  macro   i
            mov     al, [r8 + r9]           ; Get the next digit
            mov     [rcx + i], al           ; Output the digit
            endm

tableWords  macro
            shl     rax, 8                  ; Shift the current digits
            mov     al, [r8 + r9]           ; Get the next digit
            endm

computeBytes macro  i
            mov     eax, r9d                ; Convert value to 0-9
            add     eax, '0'
            add     r9d, 'A' - 10           ; Convert value to A-F
            cmp     al, '9'                 ; Verify 0-9
            cmovg   eax, r9d                ; Switch to A-F
            mov     [rcx + i], al           ; Output the digit
            endm

computeWords macro
            shl     rax, 8                  ; Shift the current digits
            mov     r8d, r9d                ; Convert value to 0-9
            add     r8d, '0'
            add     r9d, 'A' - 10           ; Convert value to A-F
            cmp     r8b, '9'                ; Verify 0-9
            cmovg   r8d, r9d                ; Switch to A-F
            mov     al, r8b                 ; Output the digit
            endm

; The nextDigit macro will be used by the code below

nextDigit   macro   i
            ifdef   use_table
                ifdef  use_bytes
                    tableBytes i
                else
                    tableWords
                endif
            else
                ifdef  use_bytes
                    computeBytes i
                else
                    computeWords
                endif
            endif
            endm

;------------------------------------------------------------------------------
; Convert value to zero terminated hex string.
; Arguments:
;     RCX  Buffer, assumed to be large enough for string and null terminator
;     RDX  Value
; Return:
;     RAX  Buffer
;
; We are going to start at the high order nibble
; and work down one at a time to the low order nibble.

            align   16
u64ToHexStr proc
            ifdef   use_table
            lea     r8, lookup              ; Converts binary to char
            endif

            mov     r9, rdx                 ; Get the nibble to convert
            shr     r9, 60
            nextDigit 0

            mov     r9, rdx
            shr     r9, 56
            and     r9d, 0fh
            nextDigit 1

            mov     r9, rdx
            shr     r9, 52
            and     r9d, 0fh
            nextDigit 2

            mov     r9, rdx
            shr     r9, 48
            and     r9d, 0fh
            nextDigit 3

            mov     r9, rdx
            shr     r9, 44
            and     r9d, 0fh
            nextDigit 4

            mov     r9, rdx
            shr     r9, 40
            and     r9d, 0fh
            nextDigit 5

            mov     r9, rdx
            shr     r9, 36
            and     r9d, 0fh
            nextDigit 6

            mov     r9, rdx
            shr     r9, 32
            and     r9d, 0fh
            nextDigit 7

            ifndef  use_bytes
            bswap   rax                     ; Output HO digits
            mov     [rcx], rax
            endif

            mov     r9d, edx
            shr     r9d, 28
            and     r9, 0fh
            nextDigit 8

            mov     r9d, edx
            shr     r9d, 24
            and     r9, 0fh
            nextDigit 9

            mov     r9d, edx
            shr     r9d, 20
            and     r9, 0fh
            nextDigit 10

            mov     r9d, edx
            shr     r9d, 16
            and     r9, 0fh
            nextDigit 11

            mov     r9d, edx
            shr     r9d, 12
            and     r9, 0fh
            nextDigit 12

            mov     r9d, edx
            shr     r9d, 8
            and     r9, 0fh
            nextDigit 13

            mov     r9d, edx
            shr     r9d, 4
            and     r9, 0fh
            nextDigit 14

            mov     r9d, edx
            and     r9, 0fh
            nextDigit 15

            ifndef  use_bytes
            bswap   rax                     ; Output LO digits
            mov     [rcx + 8], rax
            endif

            mov     byte ptr [rcx + 16], 0  ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u64ToHexStr endp

;------------------------------------------------------------------------------

            align   16
u32ToHexStr proc
            ifdef   use_table
            lea     r8, lookup              ; Converts binary to char
            endif

            mov     r9d, edx                ; Get the nibble to convert
            shr     r9d, 28
            and     r9, 0fh
            nextDigit 0

            mov     r9d, edx
            shr     r9d, 24
            and     r9, 0fh
            nextDigit 1

            mov     r9d, edx
            shr     r9d, 20
            and     r9, 0fh
            nextDigit 2

            mov     r9d, edx
            shr     r9d, 16
            and     r9, 0fh
            nextDigit 3

            mov     r9d, edx
            shr     r9d, 12
            and     r9, 0fh
            nextDigit 4

            mov     r9d, edx
            shr     r9d, 8
            and     r9, 0fh
            nextDigit 5

            mov     r9d, edx
            shr     r9d, 4
            and     r9, 0fh
            nextDigit 6

            mov     r9d, edx
            and     r9, 0fh
            nextDigit 7

            ifndef  use_bytes
            bswap   rax                     ; Output digits
            mov     [rcx], rax
            endif

            mov     byte ptr [rcx + 8], 0   ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u32ToHexStr endp

;------------------------------------------------------------------------------

            align   16
u16ToHexStr proc
            ifdef   use_table
            lea     r8, lookup              ; Converts binary to char
            endif

            mov     r9d, edx                ; Get the nibble to convert
            shr     r9d, 12
            and     r9, 0fh
            nextDigit 0

            mov     r9d, edx
            shr     r9d, 8
            and     r9, 0fh
            nextDigit 1

            mov     r9d, edx
            shr     r9d, 4
            and     r9, 0fh
            nextDigit 2

            mov     r9d, edx
            and     r9, 0fh
            nextDigit 3

            ifndef  use_bytes
            bswap   eax                     ; Output digits
            mov     [rcx], eax
            endif

            mov     byte ptr [rcx + 4], 0   ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u16ToHexStr endp

;------------------------------------------------------------------------------

            align   16
u8ToHexStr  proc
            ifdef   use_table
            lea     r8, lookup              ; Converts binary to char
            endif

            mov     r9d, edx                ; Get the nibble to convert
            shr     r9d, 4
            and     r9, 0fh
            nextDigit 0

            mov     r9d, edx
            and     r9, 0fh
            nextDigit 1

            ifndef  use_bytes
            mov     [rcx],     ah
            mov     [rcx + 1], al
            endif

            mov     byte ptr [rcx + 2], 0   ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u8ToHexStr  endp

;------------------------------------------------------------------------------

            align   16
u4ToHexStr  proc
            ifdef   use_table
            lea     r8, lookup              ; Converts binary to char
            endif

            mov     r9d, edx                ; Get the nibble to convert
            and     r9, 0fh
            nextDigit 0

            ifndef  use_bytes
            mov     [rcx], al
            endif

            mov     byte ptr [rcx + 1], 0   ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u4ToHexStr  endp

;------------------------------------------------------------------------------

            align   16

            ifdef   use_table
lookup      byte    "0123456789ABCDEF"
            endif

            end
