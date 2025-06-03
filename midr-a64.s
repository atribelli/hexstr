// midr-a64.s

            .text
            .balign 4
            .global get_midr, _get_midr



//-----------------------------------------------------------------------------
// Get the MIDR register
// Return:
//     R0  MIDR

            .balign 16
get_midr:
_get_midr:
            mrs     x0, MIDR_EL1
            ret

