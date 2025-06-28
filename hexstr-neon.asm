; hexstr-neon.asm
; Armv8-A
;
; Convert values of various sizes to zero terminated hex strings.
;     u64ToHexStr   64-bit double word
;     u32oHexStr    32-bit word
;     u16ToHexStr   16-bit half word
;     u8ToHexStr    8-bit  byte
;     u4ToHexStr    4-bit  nibble

            area    .text, code, align=4    ; align is a power of 2 exponent
            align   4                       ; align is a power of 2 value

;------------------------------------------------------------------------------
; Convert value to zero terminated hex string.
; Arguments:
;     X0  Buffer, must be at least 17 bytes in size
;     X1  Value
; Return:
;     X0  Buffer

            align   16
            global  u64ToHexStr
u64ToHexStr
            rev     x1, x1                  ; Reverse bytes to match string
            mov     v0.d[0], x1

            movi    v2.8b, #0x0f
            ushr    v1.8b, v0.8b, #4        ; Set V1 to the HO nibbles
            and     v0.8b, v0.8b, v2.8b     ; Set V0 to the LO nibbles

            movi    v2.16b, #'0'
            zip1    v0.16b, v1.16b, v0.16b  ; Interleave the HO and LO nibbles

            movi    v1.16b, #'9'
            orr     v0.16b, v0.16b, v2.16b  ; Convert binary to ascii

            movi    v2.16b, #'A' - '0' - 10
            cmgt    v1.16b, v0.16b, v1.16b  ; Determine A-F bytes

            strb    wzr, [x0, #16]          ; Zero termination
            and     v1.16b, v1.16b, v2.16b  ; Update bytes that should be A-F
            add     v0.16b, v0.16b, v1.16b

            str     q0, [x0]                ; Output the string
            ret

;------------------------------------------------------------------------------

            align   16
            global  u32ToHexStr
u32ToHexStr
            rev     w1, w1                  ; Reverse bytes to match string
            mov     v0.s[0], w1

            movi    v2.8b, #0x0f
            ushr    v1.8b, v0.8b, #4        ; Set V1 to the HO nibbles
            and     v0.8b, v0.8b, v2.8b     ; Set V0 to the LO nibbles

            movi    v2.8b, #'0'
            zip1    v0.8b, v1.8b, v0.8b     ; Interleave the HO and LO nibbles

            movi    v1.8b, #'9'
            orr     v0.8b, v0.8b, v2.8b     ; Convert binary to ascii

            movi    v2.8b, #'A' - '0' - 10
            cmgt    v1.8b, v0.8b, v1.8b     ; Determine A-F bytes

            strb    wzr, [x0, #8]           ; Zero termination
            and     v1.8b, v1.8b, v2.8b     ; Update bytes that should be A-F
            add     v0.8b, v0.8b, v1.8b

            str     d0, [x0]                ; Output the string
            ret

;------------------------------------------------------------------------------

            align   16
            global  u16ToHexStr
u16ToHexStr
            rev     w1, w1                  ; Reverse bytes to match string
            lsr     w1, w1, #16
            mov     v0.h[0], w1

            movi    v2.8b, #0x0f
            ushr    v1.8b, v0.8b, #4        ; Set V1 to the HO nibbles
            and     v0.8b, v0.8b, v2.8b     ; Set V0 to the LO nibbles

            movi    v2.8b, #'0'
            zip1    v0.8b, v1.8b, v0.8b     ; Interleave the HO and LO nibbles

            movi    v1.8b, #'9'
            orr     v0.8b, v0.8b, v2.8b     ; Convert binary to ascii

            movi    v2.8b, #'A' - '0' - 10
            cmgt    v1.8b, v0.8b, v1.8b     ; Determine A-F bytes

            strb    wzr, [x0, #4]           ; Zero termination
            and     v1.8b, v1.8b, v2.8b     ; Update bytes that should be A-F
            add     v0.8b, v0.8b, v1.8b

            str     s0, [x0]                ; Output the string
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
