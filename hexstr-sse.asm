; hexstr-sse.asm
;
; Convert values of various sizes to zero terminated hex strings.
;     u64ToHexStr   64-bit quad word
;     u32ToHexStr   32-bit double word
;     u16ToHexStr   16-bit word
;     u8ToHexStr    8-bit  byte
;     u4ToHexStr    4-bit  nibble

            .code
            align   4
            public  u64ToHexStr, u32ToHexStr, u16ToHexStr
            public  u8ToHexStr, u4ToHexStr

;------------------------------------------------------------------------------
; Some common code for the hex to string conversions.
; Arguments:
;     XMM0 Value
; Return:
;     XMM0 String
; Required:
;     SSE2

toHexStr    macro
            movq    xmm1, xmm0              ; Set xmm1 to the LO nibbles
            psrlq   xmm0, 4                 ; Set xmm0 to the HO nibbles
            pand    xmm1, oword ptr lo
            pand    xmm0, oword ptr lo
            
            punpcklbw xmm0, xmm1            ; Interleave the HO and LO nibbles

            por     xmm0, oword ptr ascii0  ; Convert binary to ascii
            movdqa  xmm1, xmm0              ; Determine which bytes should be A-F
            pcmpgtb xmm1, oword ptr ascii9

            pand    xmm1, oword ptr af      ; Update bytes that should be A-F
            paddb   xmm0, xmm1
            endm

;------------------------------------------------------------------------------
; Convert value to zero terminated hex string.
; Arguments:
;     RCX  Buffer, assumed to be large enough for string and null terminator.
;     RDX  Value
; Return:
;     RAX  Buffer
; Required:
;     SSSE3

            align   16
u64ToHexStr proc
            bswap   rdx                     ; Reverse bytes to match string
            movq    xmm0, rdx

            toHexStr

            movdqu  [rcx], xmm0             ; Output the string
            mov     byte ptr [rcx + 16], 0  ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u64ToHexStr endp

;------------------------------------------------------------------------------

            align   16
u32ToHexStr proc
            bswap   edx                     ; Reverse bytes to match string
            movd    xmm0, edx

            toHexStr

            movq    qword ptr [rcx], xmm0   ; Output the string
            mov     byte ptr [rcx + 8], 0   ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u32ToHexStr endp

;------------------------------------------------------------------------------

            align   16
u16ToHexStr proc
            movd    xmm0, edx               ; Reverse bytes to match string
            pshufb  xmm0, swap16

            toHexStr

            movd    dword ptr [rcx], xmm0   ; Output the string
            mov     byte ptr [rcx + 4], 0   ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u16ToHexStr endp

;------------------------------------------------------------------------------
; For the smaller sizes its better to just use table lookup and byte output

            align   16
u8ToHexStr  proc
            lea     r8, lookup              ; Address of lookup table

            mov     eax, edx                ; Index into lookup table
            shr     eax, 4
            and     rax, 0fh
            mov     al, [r8 + rax]          ; Hex char

            and     rdx, 0fh
            add     rdx, r8                 ; Can't use ah with r8
            mov     ah, [rdx]

            mov     [rcx], ax               ; Output the string
            mov     byte ptr [rcx + 2], 0   ; Zero terminte string
            mov     rax, rcx                ; Return original pointer
            ret
u8ToHexStr  endp

;------------------------------------------------------------------------------

            align   16
u4ToHexStr  proc
            lea     r8, lookup              ; Address of lookup table
            xor     eax, eax                ; Register to build string in

            and     rdx, 0fh                ; Index into lookup table
            mov     al, [r8 + rdx]          ; Hex char

            mov     [rcx], ax               ; Output string and zero terminaion
            mov     rax, rcx                ; Return original pointer
            ret
u4ToHexStr  endp

;------------------------------------------------------------------------------

            align   16

ascii0      byte    16 dup('0')
ascii9      byte    16 dup('9')
af          byte    16 dup('A' - '0' - 10)  ; val+'0' to val+'A'
lo          byte    16 dup(0fh)
swap16      byte    1,   0,   80h, 80h, 80h, 80h, 80h, 80h
            byte    80h, 80h, 80h, 80h, 80h, 80h, 80h, 80h

lookup      byte    "0123456789ABCDEF"

            end
