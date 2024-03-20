// hexstr-neon32.s
// Armv7-A
//
// Convert values of various sizes to zero terminated hex strings.
//     u64ToHexStr   64-bit double word
//     u32oHexStr    32-bit word
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
// Convert value to zero terminated hex string.
// Arguments:
//     R0      Buffer, must be at least 17 bytes in size
//     R3:R2   Value
// Return:
//     R0      Buffer

            .balign 16
u64ToHexStr:
            rev     r2, r2                  // Reverse bytes to match string
            rev     r3, r3
            str     r2, [r0]
            str     r3, [r0, #4]
            vld1.64 { d0 }, [r0]

            vmov.u8 d2, #0xf
            vshr.u8 d1, d0, #4              // Set D1 to the HO nibbles
            vand.8  d0, d0, d2              // Set D0 to the LO nibbles

            vmov.u8 q2, #'0'
            vzip.8  d1, d0                  // Interleave the HO and LO nibbles

            vmov.u8 q1, #'9'
            vorr.8  q0, q0, q2              // Convert binary to ascii

            vmov.u8 q2, #'A' - '0' - 10
            vcgt.u8 q1, q0, q1              // Determine A-F bytes

            vand.8  q1, q1, q2              // Update A-F bytes
            movs    r1, #0
            vadd.u8 q0, q1, q0

            vst1.8  { q0 }, [r0]            // Output the string
            strb    r1, [r0, #16]           // Zero-terminate string

            bx      lr

//-----------------------------------------------------------------------------
// Convert value to zero terminated hex string.
// Arguments:
//     R0   Buffer, must be at least 17 bytes in size
//     R1   Value
// Return:
//     R0   Buffer

            .balign 16
u32ToHexStr:
            rev     r1, r1                  // Reverse bytes to match string
            str     r1, [r0]
            vld1.32 { d0 }, [r0]

            vmov.u8 d2, #0xf
            vshr.u8 d1, d0, #4              // Set D1 to the HO nibbles
            vand.8  d0, d0, d2              // Set D0 to the LO nibbles

            vmov.u8 d2, #'0'
            vzip.8  d1, d0                  // Interleave the HO and LO nibbles

            vmov.u8 d0, #'9'
            vorr.8  d1, d1, d2              // Convert binary to ascii

            vmov.u8 d2, #'A' - '0' - 10
            vcgt.u8 d0, d1, d0              // Determine A-F bytes

            vand.8  d0, d0, d2              // Update A-F bytes
            movs    r2, #0
            vadd.u8 d0, d1, d0

            vst1.8  { d0 }, [r0]            // Output the string
            strb    r2, [r0, #8]            // Zero-terminate string

            bx      lr

//-----------------------------------------------------------------------------

            .balign 16
u16ToHexStr:
            rev16   r1, r1                  // Reverse bytes to match string
            strh    r1, [r0]
            vld1.16 { d0 }, [r0]

            vmov.u8 d2, #0xf
            vshr.u8 d1, d0, #4              // Set D1 to the HO nibbles
            vand.8  d0, d0, d2              // Set D0 to the LO nibbles

            vmov.u8 d2, #'0'
            vzip.8  d1, d0                  // Interleave the HO and LO nibbles

            vmov.u8 d0, #'9'
            vorr.8  d1, d1, d2              // Convert binary to ascii

            vmov.u8 d2, #'A' - '0' - 10
            vcgt.u8 d0, d1, d0              // Determine A-F bytes

            vand.8  d0, d0, d2              // Update A-F bytes
            movs    r2, #0
            vadd.u8 d0, d1, d0

            vst1.32  { d0[0] }, [r0]        // Output the string
            strb    r2, [r0, #4]            // Zero-terminate string

            bx      lr

//-----------------------------------------------------------------------------
// For the smaller sizes its better to just use table lookup and byte output

            .balign 16
u8ToHexStr:
            adr     r2, lookup              // Get ascii from lookup table

            lsr     r3, r1, #4              // Position desired nibble
            and     r3, r3, #0x0f           // and create an index
            ldrb    r3, [r2, r3]            // Lookup the ascii character
            strb    r3, [r0]                // and output it

            and     r3, r1, #0x0f
            ldrb    r3, [r2, r3]
            strh    r3, [r0, #1]            // Output digit and termination

            bx      lr

//-----------------------------------------------------------------------------

            .balign 16
u4ToHexStr:
            adr     r2, lookup              // Get ascii from lookup table

            and     r3, r1, #0x0f           // Create an index
            ldrb    r3, [r2, r3]            // Lookup the digit
            strh    r3, [r0]                // and output it with termination

            bx      lr

//-----------------------------------------------------------------------------

            .balign 16

lookup:     .ascii  "0123456789ABCDEF"

