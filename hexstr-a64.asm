; hexstr-a64.asm
;
; Convert values of various sizes to zero terminated hex strings.
;     u64ToHexStr   64-bit double word
;     u32ToHexStr   32-bit word
;     u16ToHexStr   16-bit half word
;     u8ToHexStr    8-bit  byte
;     u4ToHexStr    4-bit  nibble

            area    .text, code, align=4    ; align is a power of 2 exponent
            align   4                       ; align is a power of 2 value

;------------------------------------------------------------------------------
; Comment/uncomment these symbol definition to control implementation
; of code.
;
; use_table allows table lookup rather than computation of chars.
; use_bytes allows individuals bytes to be output rather than collected
; in a register to be output as a word later.

use_table   equ    1
use_bytes   equ    1

            if      :def: use_table
            info    0, "Conditional Assembly: Lookup digits"
            else
            info    0, "Conditional Assembly: Compute digits"
            endif
            if      :def: use_bytes
            info    0, "Conditional Assembly: Output bytes"
            else
            info    0, "Conditional Assembly: Output words"
            endif
            
;-----------------------------------------------------------------------------
; Macros with the code for different implementations.
; Table vs compute, bytes vs words.
; What works best depends on the architecture, these allow us to easily test.
; Arguments:
;     X0  Buffer if use_bytes defined
;     X2  Value
;     X3  Lookup table if use_table defined
;     X4  Current digits if use_bytes not defined
;     i   Next position in buffer if use_bytes defined
; Return:
;     X0  Buffer has new digit if use_bytes defined
;     X4  Cuurrent digits shifted left if use_bytes not defined
;     X2  New digit

            ; These macros are not used directly,
            ; one of them will be used in nextDigit

            macro
            tableBytes $i
            ldrb    w2, [x3, x2]            ; Get the next digit
            strb    w2, [x0, #$i]           ; Output the digit
            mend

            macro
            tableWords
            lsl     x4, x4, #8              ; Shift the current digits
            ldrb    w2, [x3, x2]            ; Get the next digit
            orr     x4, x4, x2
            mend

            macro
            computeBytes $i
            mov     x5, x2
            add     x2, x2, #'0'            ; Convert value to 0-9
            add     x5, x5, #'A' - 10       ; Convert value to A-F
            cmp     x2, #'9'                ; Verify 0-9
            csel    x2, x2, x5, ls          ; Switch to A-F
            strb    w2, [x0, #$i]           ; Output the digit
            mend

            macro
            computeWords
            lsl     x4, x4, #8              ; Shift the current digits
            mov     x5, x2
            add     x2, x2, #'0'            ; Convert value to 0-9
            add     x5, x5, #'A' - 10       ; Convert value to A-F
            cmp     x2, #'9'                ; Verify 0-9
            csel    x2, x2, x5, ls          ; Switch to A-F
            orr     x4, x4, x2              ; Output the digit
            mend

            ; The nextDigit macro will be used by the code below

            macro
            nextDigit $i
            if      :def: use_table
                if  :def: use_bytes
                    tableBytes $i
                else
                    tableWords
                endif
            else
                if  :def: use_bytes
                    computeBytes $i
                else
                    computeWords
                endif
            endif
            mend

;------------------------------------------------------------------------------
; Convert value to zero terminated hex string.
; Arguments:
;     X0  Buffer, assumed to be large enough for string and null terminator
;     X1  Value
; Return:
;     X0  Buffer
;
; We are going to start at the high order nibble
; and work down one at a time to the low order nibble.

            align   16
            global  u64ToHexStr
u64ToHexStr
            if      :def: use_table
            adr     x3, lookup              ; Converts binary to char
            endif

            lsr     x2, x1, #60             ; Get the nibble to convert
            nextDigit 0

            lsr     x2, x1, #56
            and     w2, w2, #0xf
            nextDigit 1

            lsr     x2, x1, #52
            and     w2, w2, #0xf
            nextDigit 2

            lsr     x2, x1, #48
            and     w2, w2, #0xf
            nextDigit 3

            lsr     x2, x1, #44
            and     w2, w2, #0xf
            nextDigit 4

            lsr     x2, x1, #40
            and     w2, w2, #0xf
            nextDigit 5

            lsr     x2, x1, #36
            and     w2, w2, #0xf
            nextDigit 6

            lsr     x2, x1, #32
            and     w2, w2, #0xf
            nextDigit 7

            if      :lnot: :def: use_bytes
            rev     x4, x4                  ; Output HO digits
            str     x4, [x0]
            endif

            lsr     w2, w1, #28
            and     x2, x2, #0xf
            nextDigit 8

            lsr     w2, w1, #24
            and     x2, x2, #0xf
            nextDigit 9

            lsr     w2, w1, #20
            and     x2, x2, #0xf
            nextDigit 10

            lsr     w2, w1, #16
            and     x2, x2, #0xf
            nextDigit 11

            lsr     w2, w1, #12
            and     x2, x2, #0xf
            nextDigit 12

            lsr     w2, w1, #8
            and     x2, x2, #0xf
            nextDigit 13

            lsr     w2, w1, #4
            and     x2, x2, #0xf
            nextDigit 14

            and     x2, x1, #0xf
            nextDigit 15

            if      :lnot: :def: use_bytes
            rev     x4, x4                  ; Output LO digits
            str     x4, [x0, #8]
            endif

            strb    wzr, [x0, #16]          ; Zero terminte string
            ret

;------------------------------------------------------------------------------

            align   16
            global  u32ToHexStr
u32ToHexStr
            if      :def: use_table
            adr     x3, lookup              ; Converts binary to char
            endif

            lsr     w2, w1, #28
            and     x2, x2, #0xf
            nextDigit 0

            lsr     w2, w1, #24
            and     x2, x2, #0xf
            nextDigit 1

            lsr     w2, w1, #20
            and     x2, x2, #0xf
            nextDigit 2

            lsr     w2, w1, #16
            and     x2, x2, #0xf
            nextDigit 3

            lsr     w2, w1, #12
            and     x2, x2, #0xf
            nextDigit 4

            lsr     w2, w1, #8
            and     x2, x2, #0xf
            nextDigit 5

            lsr     w2, w1, #4
            and     x2, x2, #0xf
            nextDigit 6

            and     x2, x1, #0xf
            nextDigit 7

            if      :lnot: :def: use_bytes
            rev     x4, x4                  ; Output digits
            str     x4, [x0]
            endif

            strb    wzr, [x0, #8]           ; Zero terminte string
            ret

;------------------------------------------------------------------------------

            align   16
            global  u16ToHexStr
u16ToHexStr
            if      :def: use_table
            adr     x3, lookup              ; Converts binary to char
            endif

            lsr     w2, w1, #12
            and     x2, x2, #0xf
            nextDigit 0

            lsr     w2, w1, #8
            and     x2, x2, #0xf
            nextDigit 1

            lsr     w2, w1, #4
            and     x2, x2, #0xf
            nextDigit 2

            and     x2, x1, #0xf
            nextDigit 3

            if      :lnot: :def: use_bytes
            rev     w4, w4                  ; Output digits
            str     w4, [x0]
            endif

            strb    wzr, [x0, #4]           ; Zero terminte string
            ret

;------------------------------------------------------------------------------
; For the smaller sizes its better to just use table lookup and byte output

            align   16
            global  u8ToHexStr
u8ToHexStr
            adr     x2, lookup              ; Get ascii from lookup table

            lsr     x3, x1, #4              ; Position desired nibble
            and     x3, x3, #0x0f           ; and create an index
            ldrb    w3, [x2, x3]            ; Lookup the ascii character
            strb    w3, [x0]                ; and output it

            and     x3, x1, #0x0f
            ldrb    w3, [x2, x3]
            strh    w3, [x0, #1]            ; Output digit and termination
            ret

;------------------------------------------------------------------------------

            align   16
            global  u4ToHexStr
u4ToHexStr
            adr     x2, lookup              ; Get ascii from lookup table

            and     x3, x1, #0x0f           ; Create an index
            ldrb    w3, [x2, x3]            ; Lookup the digit
            strh    w3, [x0]                ; and output it with termination
            ret

;------------------------------------------------------------------------------

            align   16

lookup      dcb     "0123456789ABCDEF"

            end
