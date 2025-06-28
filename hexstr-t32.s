// hexstr-thumb.s
//
// Convert values of various sizes to zero terminated hex strings.
//     u64ToHexStr   64-bit double word
//     u32ToHexStr   32-bit word
//     u16ToHexStr   16-bit half word
//     u8ToHexStr    8-bit  byte
//     u4ToHexStr    4-bit  nibble

            .arch   armv7-a
            .fpu    neon-vfpv3

            .ifdef  IsLinux
            .section .note.GNU-stack, "", %progbits
            .endif

            .text
            .balign 4
            .global u64ToHexStr, u32ToHexStr, u16ToHexStr
            .global u8ToHexStr, u4ToHexStr

//-----------------------------------------------------------------------------
// Comment/uncomment these symbol definition to control implementation
// of code.
//
// use_table allows table lookup rather than computation of chars.
// use_bytes allows individuals bytes to be output rather than collected
// in a register to be output as a word later.

            .set    use_table, 1
            .set    use_bytes, 1

            .ifdef  use_table
            .print  "Conditional Assembly: Lookup digits"
            .else
            .print  "Conditional Assembly: Compute digits"
            .endif
            .ifdef  use_bytes
            .print  "Conditional Assembly: Output bytes"
            .else
            .print  "Conditional Assembly: Output words"
            .endif

//-----------------------------------------------------------------------------
// Macros with the code for different implementations.
// Table vs compute, bytes vs words.
// What works best depends on the architecture, these allow us to easily test.
// Arguments:
//     R0  Buffer if use_bytes defined
//     R4  Value
//     R5  Lookup table if use_table defined
//     R6  Current digits if use_bytes not defined
//     i   Next position in buffer if use_bytes defined
// Return:
//     R0  Buffer has new digit if use_bytes defined
//     R6  Cuurrent digits shifted left if use_bytes not defined
//     R4  New digit

            // These macros are not used directly,
            // one of them will be used in nextDigit

            .macro  tableBytes, i
            ldrb    r4, [r5, r4]            // Get the next digit
            strb    r4, [r0, #\i]           // Output the digit
            .endm

            .macro  tableWords
            lsl     r6, r6, #8              // Shift the current digits
            ldrb    r4, [r5, r4]            // Get the next digit
            orr     r6, r6, r4
            .endm

            .macro  computeBytes, i
            cmp     r4, #9                  // Determine conversion
            bls     1f
            add     r4, r4, #'A' - 10       // Convert value to A-F
            bal     2f
1:          add     r4, r4, #'0'            // Convert value to 0-9
2:          strb    r4, [r0, #\i]           // Output the digit
            .endm

            .macro  computeWords
            lsl     r6, r6, #8              // Shift the current digits
            cmp     r4, #9                  // Select the correct digit
            bls     1f
            add     r4, r4, #'A' - 10       // Convert value to A-F
            bal     2f
1:          add     r4, r4, #'0'            // Convert value to 0-9
2:          orr     r6, r6, r4              // Output the digit
            .endm

            // The nextDigit macro will be used by the code below

            .macro  nextDigit, i
            .ifdef  use_table
                .ifdef  use_bytes
                    tableBytes \i
                .else
                    tableWords
                .endif
            .else
                .ifdef  use_bytes
                    computeBytes \i
                .else
                    computeWords
                .endif
            .endif
            .endm

//-----------------------------------------------------------------------------
// Convert value to zero terminated hex string.
// Arguments:
//     R0     Buffer, assumed to be large enough for string and null terminator
//     R3:R2  Value
// Return:
//     R0     Buffer
//
// We are going to start at the high order nibble
// and work down one at a time to the low order nibble.

            .arm
            .balign 16
u64ToHexStr:
            add     r1, pc, #1              // Switch to thumb mode
            bx      r1
            .thumb

            push    { r4, r7 }
            mov     r7, #0xf

            .ifdef  use_table
            push    { r5 }
            adr     r5, lookup              // Converts binary to char
            .endif

            .ifndef use_bytes
            push    { r6 }
            .endif

            lsr     r4, r3, #28             // Get the nibble to convert
            nextDigit 0

            lsr     r4, r3, #24
            and     r4, r4, r7
            nextDigit 1

            lsr     r4, r3, #20
            and     r4, r4, r7
            nextDigit 2

            lsr     r4, r3, #16
            and     r4, r4, r7
            nextDigit 3

            .ifndef use_bytes
            rev     r6, r6                  // Output HO digits
            str     r6, [r0]
            .endif

            lsr     r4, r3, #12
            and     r4, r4, r7
            nextDigit 4

            lsr     r4, r3, #8
            and     r4, r4, r7
            nextDigit 5

            lsr     r4, r3, #4
            and     r4, r4, r7
            nextDigit 6

            mov     r4, r3
            and     r4, r4, r7
            nextDigit 7

            .ifndef use_bytes
            rev     r6, r6                  // Output HO digits
            str     r6, [r0, #4]
            .endif

            lsr     r4, r2, #28
            nextDigit 8

            lsr     r4, r2, #24
            and     r4, r4, r7
            nextDigit 9

            lsr     r4, r2, #20
            and     r4, r4, r7
            nextDigit 10

            lsr     r4, r2, #16
            and     r4, r4, r7
            nextDigit 11

            .ifndef use_bytes
            rev     r6, r6                  // Output LO digits
            str     r6, [r0, #8]
            .endif

            lsr     r4, r2, #12
            and     r4, r4, r7
            nextDigit 12

            lsr     r4, r2, #8
            and     r4, r4, r7
            nextDigit 13

            lsr     r4, r2, #4
            and     r4, r4, r7
            nextDigit 14

            mov     r4, r2
            and     r4, r4, r7
            nextDigit 15

            .ifndef use_bytes
            rev     r6, r6                  // Output LO digits
            str     r6, [r0, #12]
            .endif

            movs    r4, #0
            strb    r4, [r0, #16]           // Zero terminte string

            .ifndef use_bytes
            pop     { r6 }
            .endif

            .ifdef  use_table
            pop     { r5 }
            .endif

            pop     { r4, r7 }
            bx      lr

//-----------------------------------------------------------------------------
// Convert value to zero terminated hex string.
// Arguments:
//     R0  Buffer, assumed to be large enough for string and null terminator
//     R1  Value
// Return:
//     R0  Buffer
//
// We are going to start at the high order nibble
// and work down one at a time to the low order nibble.


            .arm
            .balign 16
u32ToHexStr:
            add     r2, pc, #1              // Switch to thumb mode
            bx      r2
            .thumb

            push    { r4, r7 }
            mov     r7, #0xf

            .ifdef  use_table
            push    { r5 }
            adr     r5, lookup              // Converts binary to char
            .endif

            .ifndef use_bytes
            push    { r6 }
            .endif

            lsr     r4, r1, #28
            and     r4, r4, r7
            nextDigit 0

            lsr     r4, r1, #24
            and     r4, r4, r7
            nextDigit 1

            lsr     r4, r1, #20
            and     r4, r4, r7
            nextDigit 2

            lsr     r4, r1, #16
            and     r4, r4, r7
            nextDigit 3

            .ifndef use_bytes
            rev     r6, r6                  // Output digits
            str     r6, [r0]
            .endif

            lsr     r4, r1, #12
            and     r4, r4, r7
            nextDigit 4

            lsr     r4, r1, #8
            and     r4, r4, r7
            nextDigit 5

            lsr     r4, r1, #4
            and     r4, r4, r7
            nextDigit 6

            mov     r4, r1
            and     r4, r4, r7
            nextDigit 7

            .ifndef use_bytes
            rev     r6, r6                  // Output digits
            str     r6, [r0, #4]
            .endif

            movs    r4, #0
            strb    r4, [r0, #8]            // Zero terminte string

            .ifndef use_bytes
            pop     { r6 }
            .endif

            .ifdef  use_table
            pop     { r5 }
            .endif

            pop     { r4, r7 }
            bx      lr

//-----------------------------------------------------------------------------

            .arm
            .balign 16
u16ToHexStr:
            add     r2, pc, #1              // Switch to thumb mode
            bx      r2
            .thumb

            push    { r4, r7 }
            mov     r7, #0xf

            .ifdef  use_table
            push    { r5 }
            adr     r5, lookup              // Converts binary to char
            .endif

            .ifndef use_bytes
            push    { r6 }
            .endif

            lsr     r4, r1, #12
            and     r4, r4, r7
            nextDigit 0

            lsr     r4, r1, #8
            and     r4, r4, r7
            nextDigit 1

            lsr     r4, r1, #4
            and     r4, r4, r7
            nextDigit 2

            mov     r4, r1
            and     r4, r4, r7
            nextDigit 3

            .ifndef use_bytes
            rev     r6, r6                  // Output digits
            str     r6, [r0]
            .endif

            movs    r4, #0
            strb    r4, [r0, #4]            // Zero terminte string

            .ifndef use_bytes
            pop     { r6 }
            .endif

            .ifdef  use_table
            pop     { r5 }
            .endif

            pop     { r4, r7 }
            bx      lr

//-----------------------------------------------------------------------------
// For the smaller sizes its better to just use table lookup and byte output

            .arm
            .balign 16
u8ToHexStr:
            add     r2, pc, #1              // Switch to thumb mode
            bx      r2
            .thumb

            push    { r4 }
            mov     r4, #0x0f

            adr     r2, lookup              // Get ascii from lookup table

            lsr     r3, r1, #4              // Position desired nibble
            and     r3, r3, r4              // and create an index
            ldrb    r3, [r2, r3]            // Lookup the ascii character
            strb    r3, [r0]                // and output it

            mov     r3, r1
            and     r3, r3, r4
            ldrb    r3, [r2, r3]
            add     r0, r0, #1
            strh    r3, [r0]                // Output digit and termination
            sub     r0, r0, #1              // Restore buffer pointer

            pop     { r4 }
            bx      lr

//-----------------------------------------------------------------------------

            .arm
            .balign 16
u4ToHexStr:
            add     r2, pc, #1              // Switch to thumb mode
            bx      r2
            .thumb

            push    { r4 }
            mov     r4, #0x0f

            adr     r2, lookup              // Get ascii from lookup table

            mov     r3, r1
            and     r3, r3, r4              // Create an index
            ldrb    r3, [r2, r3]            // Lookup the digit
            strh    r3, [r0]                // and output it with termination

            pop     { r4 }
            bx      lr

//-----------------------------------------------------------------------------

            .balign 16

lookup:     .ascii  "0123456789ABCDEF"

