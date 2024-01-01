// hexstr-a32.s
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
            .align  2
            .global u64ToHexStr, u32ToHexStr, u16ToHexStr
            .global u8ToHexStr, u4ToHexStr

//-----------------------------------------------------------------------------
// Comment/uncomment these symbol definition to control implementation
// of code.
//
// use_table allows table lookup rather than computation of chars.
// use_bytes allows individuals bytes to be output rather than collected
// in a register to be output as a word later.

//            .set    use_table, 1
//            .set    use_bytes, 1

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
            cmp     r4, #'9'                // Select the correct digit
            addgt   r4, r4, #'A' - 10       // Convert value to A-F
            addls   r4, r4, #'0'            // Convert value to 0-9
            strb    r4, [r0, #\i]           // Output the digit
            .endm

            .macro  computeWords
            lsl     r6, r6, #8              // Shift the current digits
            cmp     r4, #'9'                // Select the correct digit
            addgt   r4, r4, #'A' - 10       // Convert value to A-F
            addls   r4, r4, #'0'            // Convert value to 0-9
            orr     r6, r6, r4              // Output the digit
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

            .align  4
u64ToHexStr:
            .ifdef  use_table
            adr     r5, lookup              // Converts binary to char
            .endif

            lsr     r4, r3, #28             // Get the nibble to convert
            nextDigit 0

            lsr     r4, r3, #24
            and     r4, r4, #0xf
            nextDigit 1

            lsr     r4, r3, #20
            and     r4, r4, #0xf
            nextDigit 2

            lsr     r4, r3, #16
            and     r4, r4, #0xf
            nextDigit 3

            .ifndef use_bytes
            rev     r6, r6                  // Output HO digits
            str     r6, [r0]
            .endif

            lsr     r4, r3, #12
            and     r4, r4, #0xf
            nextDigit 4

            lsr     r4, r3, #8
            and     r4, r4, #0xf
            nextDigit 5

            lsr     r4, r3, #4
            and     r4, r4, #0xf
            nextDigit 6

            and     r4, r3, #0xf
            nextDigit 7

            .ifndef use_bytes
            rev     r6, r6                  // Output HO digits
            str     r6, [r0, #4]
            .endif

            lsr     r4, r2, #28
            nextDigit 8

            lsr     r4, r2, #24
            and     r4, r4, #0xf
            nextDigit 9

            lsr     r4, r2, #20
            and     r4, r4, #0xf
            nextDigit 10

            lsr     r4, r2, #16
            and     r4, r4, #0xf
            nextDigit 11

            .ifndef use_bytes
            rev     r6, r6                  // Output LO digits
            str     r6, [r0, #8]
            .endif

            lsr     r4, r2, #12
            and     r4, r4, #0xf
            nextDigit 12

            lsr     r4, r2, #8
            and     r4, r4, #0xf
            nextDigit 13

            lsr     r4, r2, #4
            and     r4, r4, #0xf
            nextDigit 14

            and     r4, r2, #0xf
            nextDigit 15

            .ifndef use_bytes
            rev     r6, r6                  // Output LO digits
            str     r6, [r0, #12]
            .endif

            movs    r4, #0
            strb    r4, [r0, #16]           // Zero terminte string

            bx      lr

//-----------------------------------------------------------------------------

            .align  4
u32ToHexStr:
            .ifdef  use_table
            adr     r5, lookup              // Converts binary to char
            .endif

            lsr     r4, r2, #28
            and     r4, r4, #0xf
            nextDigit 0

            lsr     r4, r2, #24
            and     r4, r4, #0xf
            nextDigit 1

            lsr     r4, r2, #20
            and     r4, r4, #0xf
            nextDigit 2

            lsr     r4, r2, #16
            and     r4, r4, #0xf
            nextDigit 3

            .ifndef use_bytes
            rev     r6, r6                  // Output digits
            str     r6, [r0]
            .endif

            lsr     r4, r2, #12
            and     r4, r4, #0xf
            nextDigit 4

            lsr     r4, r2, #8
            and     r4, r4, #0xf
            nextDigit 5

            lsr     r4, r2, #4
            and     r4, r4, #0xf
            nextDigit 6

            and     r4, r2, #0xf
            nextDigit 7

            .ifndef use_bytes
            rev     r6, r6                  // Output digits
            str     r6, [r0, #4]
            .endif

            movs    r4, #0
            strb    r4, [r0, #8]            // Zero terminte string

            bx      lr

//-----------------------------------------------------------------------------

            .align  4
u16ToHexStr:
            .ifdef  use_table
            adr     r5, lookup              // Converts binary to char
            .endif

            lsr     r4, r2, #12
            and     r4, r4, #0xf
            nextDigit 0

            lsr     r4, r2, #8
            and     r4, r4, #0xf
            nextDigit 1

            lsr     r4, r2, #4
            and     r4, r4, #0xf
            nextDigit 2

            and     r4, r2, #0xf
            nextDigit 3

            .ifndef use_bytes
            rev     r6, r6                  // Output digits
            str     r6, [r0]
            .endif

            movs    r4, #0
            strb    r4, [r0, #4]            // Zero terminte string

            bx      lr

//-----------------------------------------------------------------------------

            .align  4
u8ToHexStr:
            .ifdef  use_table
            adr     r5, lookup              // Converts binary to char
            .endif

            lsr     r4, r2, #4
            and     r4, r4, #0xf
            nextDigit 0

            and     r4, r2, #0xf
            nextDigit 1

            .ifndef use_bytes
            rev16   r6, r6
            strh    r6, [r0]                // Output digits
            .endif

            movs    r4, #0
            strb    r4, [r0, #2]            // Zero terminte string

            bx      lr

//-----------------------------------------------------------------------------

            .align  4
u4ToHexStr:
            .ifdef  use_table
            adr     r5, lookup              // Converts binary to char
            .endif

            and     r4, r2, #0xf
            nextDigit 0

            .ifndef use_bytes
            strb    r6, [r0]                // Output digits
            .endif

            movs    r4, #0
            strb    r4, [r0, #1]            // Zero terminte string

            bx      lr

//-----------------------------------------------------------------------------

            .align  4

            .ifdef  use_table
lookup:     .ascii  "0123456789ABCDEF"
            .endif

