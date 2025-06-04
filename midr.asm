; midr.asm

            area    .text, code
            align   4



;------------------------------------------------------------------------------
; Get the MIDR register
; Return:
;   X0  MIDR

            align   8
            global  get_midr
get_midr
            mrs     x0, MIDR_EL1
            ret

            end
