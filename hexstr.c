// hexstr.c
//
// hexstr.c is used to build both the pure c version, hexstr-c,
// and the c version supplemented with intrinsics for some cases, hexstr-intrin.
// Which version is built depends upon whether USE_SIMD is defined.
//
// Convert values of various sizes to zero terminated hex strings.
//     u64ToHexStr   64-bit double word
//     u32ToHexStr   32-bit word
//     u16ToHexStr   16-bit half word
//     u8ToHexStr    8-bit  byte
//     u4ToHexStr    4-bit  nibble

#include <stdint.h>
#include <stdalign.h>

#if   defined(USE_SIMD) && defined(__aarch64__)

#include <arm_neon.h>

#elif defined(USE_SIMD) && defined(__arm__)

#include <arm_neon.h>

// Use unions to access the first element of a double element data type

union uint8x16 {
    uint8x16x2_t    x2;
    uint8x16_t      x1;
};

union uint8x8 {
    uint8x8x2_t x2;
    uint8x8_t   x1;
};

#elif defined(USE_SIMD) && (defined(__x86_64__) || defined(_M_X64))

#include <immintrin.h>

#endif

#include "hexstr.h"



const uint8_t convert0toA = 'A' - '0' - 10;     // val+'0' to val+'A'
const uint8_t invert0ToA  = ~('A' - '0' - 10);  // Invert the bits for BIC

alignas(32)
uint8_t ascii0[16] = { '0', '0', '0', '0', '0', '0', '0', '0',
                       '0', '0', '0', '0', '0', '0', '0', '0' };

alignas(32)
uint8_t ascii9[16] = { '9', '9', '9', '9', '9', '9', '9', '9',
                       '9', '9', '9', '9', '9', '9', '9', '9' };

alignas(32)
uint8_t af[16]     = { 'A' - '0' - 10, 'A' - '0' - 10, 'A' - '0' - 10,
                       'A' - '0' - 10, 'A' - '0' - 10, 'A' - '0' - 10,
                       'A' - '0' - 10, 'A' - '0' - 10, 'A' - '0' - 10,
                       'A' - '0' - 10, 'A' - '0' - 10, 'A' - '0' - 10,
                       'A' - '0' - 10, 'A' - '0' - 10, 'A' - '0' - 10,
                       'A' - '0' - 10 };

alignas(32)
const char *lookup = "0123456789ABCDEF";

alignas(32)
uint64_t   lo      = 0x0F0F0F0F0F0F0F0F;
uint8_t    invaf   = ~('A' - '0' - 10);
uint8_t    ho      = 0xF0;



//----------------------------------------------------------------------------
// Convert value to zero terminated decimal string.
// Arguments:
//     buffer   Pointer to a buffer assumed to be large enough for
//              string and null terminator, and assumed to be aligned to an
//              even address.
//     value    Numeric value to convert.
// Return:
//              Pointer to buffer

const char *u64ToHexStr(char *buffer, uint64_t value) {
#if defined(USE_SIMD) && defined(__aarch64__)
    
    // ARM NEON 64 Intrinsics

    uint8x16_t string, temp, clear;

    value  = __builtin_bswap64(value);      // Reverse bytes to match string
    string = vld1q_u8((uint8_t *) &value);
    
    temp   = vshrq_n_u8(string, 4);         // Set temp   to the HO nibbles
    clear  = vld1q_dup_u8(&ho);             // and string to the LO nibbles
    string = vbicq_u8(string, clear);
    
    string = vzip1q_u8(temp, string);       // Interleave the HO and LO nibbles
    
    temp   = vld1q_dup_u8(ascii0);          // Convert binary to ascii,
    string = vorrq_u8(string, temp);        // note only 0-9 will be correct
    
    temp   = vld1q_dup_u8(ascii9);          // Determine which bytes
    temp   = vcgtq_u8(string, temp);        // should be A-F
    
    clear  = vld1q_dup_u8(&invaf);          // Update bytes that should be A-F
    temp   = vbicq_u8(temp, clear);
    string = vaddq_u8(string, temp);

    vst1q_u8((uint8_t *) buffer, string);   // Output the string

#elif defined(USE_SIMD) && defined(__arm__)
    
    // ARM NEON 32 Intrinsics

    union uint8x16  string;
    uint8x16_t      temp, clear;

    value     = __builtin_bswap64(value);   // Reverse bytes to match string
    string.x1 = vld1q_u8((uint8_t *) &value);
    
    temp      = vshrq_n_u8(string.x1, 4);   // Set temp   to the HO nibbles
    clear     = vld1q_dup_u8(&ho);          // and string to the LO nibbles
    string.x1 = vbicq_u8(string.x1, clear);
    
    string.x2 = vzipq_u8(temp, string.x1);  // Interleave the HO and LO nibbles
    
    temp      = vld1q_dup_u8(ascii0);       // Convert binary to ascii,
    string.x1 = vorrq_u8(string.x1, temp);  // note only 0-9 will be correct
    
    temp      = vld1q_dup_u8(ascii9);       // Determine which bytes
    temp      = vcgtq_u8(string.x1, temp);  // should be A-F
    
    clear     = vld1q_dup_u8(&invaf);       // Update bytes that should be A-F
    temp      = vbicq_u8(temp, clear);
    string.x1 = vaddq_u8(string.x1, temp);

    vst1q_u8((uint8_t *) buffer, string.x1); // Output the string

#elif defined(USE_SIMD) && (defined(__x86_64__) || defined(_M_X64))
    
    // Intel SSE Intrinsics

    __m128i string, temp, mask;

#ifdef _MSC_VER
    value = _byteswap_uint64(value);        // Reverse bytes to match string
#else
    value  = __builtin_bswap64(value);
#endif

    string = _mm_cvtsi64_si128(value);

    mask   = _mm_loadu_si64(&lo);           // Set temp   to the HO nibbles
    temp   = _mm_srli_epi64(string, 4);     // and string to the LO nibbles
    temp   = _mm_and_si128(temp,   mask);
    string = _mm_and_si128(string, mask);

    string = _mm_unpacklo_epi8(temp, string); // Interleave the HO and LO nibbles
    
    temp   = _mm_loadu_si128((__m128i *) ascii0); // Convert binary to ascii,
    string = _mm_or_si128(string, temp);          // note only 0-9 will be correct

    temp   = _mm_loadu_si128((__m128i *) ascii9); // Determine which bytes
    mask   = _mm_cmpgt_epi8(string, temp);        // should be A-F
    
    temp   = _mm_loadu_si128((__m128i *) af); // Update bytes that should be A-F
    temp   = _mm_and_si128(temp, mask);
    string = _mm_add_epi8(string, temp);
    
    _mm_storeu_si128((__m128i *) buffer, string); // Output the string

#else
    
    // Default C implementation
    
    buffer[ 0] = lookup[ value >> 60];
    buffer[ 1] = lookup[(value >> 56) & 0x0F];
    buffer[ 2] = lookup[(value >> 52) & 0x0F];
    buffer[ 3] = lookup[(value >> 48) & 0x0F];
    buffer[ 4] = lookup[(value >> 44) & 0x0F];
    buffer[ 5] = lookup[(value >> 40) & 0x0F];
    buffer[ 6] = lookup[(value >> 36) & 0x0F];
    buffer[ 7] = lookup[(value >> 32) & 0x0F];
    buffer[ 8] = lookup[(value >> 28) & 0x0F];
    buffer[ 9] = lookup[(value >> 24) & 0x0F];
    buffer[10] = lookup[(value >> 20) & 0x0F];
    buffer[11] = lookup[(value >> 16) & 0x0F];
    buffer[12] = lookup[(value >> 12) & 0x0F];
    buffer[13] = lookup[(value >>  8) & 0x0F];
    buffer[14] = lookup[(value >>  4) & 0x0F];
    buffer[15] = lookup[ value        & 0x0F];
#endif

    buffer[16] = 0;

    return buffer;
}



//----------------------------------------------------------------------------

const char *u32ToHexStr(char *buffer, uint32_t value) {
#if defined(USE_SIMD) && defined(__aarch64__)

    // ARM NEON 64 Intrinsics

    uint8x8_t string, temp, clear;

    value  = __builtin_bswap32(value);      // Reverse bytes to match string
    string = vld1_u8((uint8_t *) &value);
    
    temp   = vshr_n_u8(string, 4);          // Set temp   to the HO nibbles
    clear  = vld1_dup_u8(&ho);              // and string to the LO nibbles
    string = vbic_u8(string, clear);
    
    string = vzip1_u8(temp, string);        // Interleave the HO and LO nibbles
    
    temp   = vld1_dup_u8(ascii0);           // Convert binary to ascii,
    string = vorr_u8(string, temp);         // note only 0-9 will be correct
    
    temp   = vld1_dup_u8(ascii9);           // Determine which bytes
    temp   = vcgt_u8(string, temp);         // should be A-F
    
    clear  = vld1_dup_u8(&invaf);           // Update bytes that should be A-F
    temp   = vbic_u8(temp, clear);
    string = vadd_u8(string, temp);

    vst1_u8((uint8_t *) buffer, string);    // Output the string

#elif defined(USE_SIMD) && defined(__arm__)
    
    // ARM NEON 32 Intrinsics

    union uint8x8   string;
    uint8x8_t       temp, clear;

    value     = __builtin_bswap32(value);   // Reverse bytes to match string
    string.x1 = vld1_u8((uint8_t *) &value);
    
    temp      = vshr_n_u8(string.x1, 4);    // Set temp   to the HO nibbles
    clear     = vld1_dup_u8(&ho);           // and string to the LO nibbles
    string.x1 = vbic_u8(string.x1, clear);
    
    string.x2 = vzip_u8(temp, string.x1);   // Interleave the HO and LO nibbles
    
    temp      = vld1_dup_u8(ascii0);        // Convert binary to ascii,
    string.x1 = vorr_u8(string.x1, temp);   // note only 0-9 will be correct
    
    temp      = vld1_dup_u8(ascii9);        // Determine which bytes
    temp      = vcgt_u8(string.x1, temp);   // should be A-F
    
    clear     = vld1_dup_u8(&invaf);        // Update bytes that should be A-F
    temp      = vbic_u8(temp, clear);
    string.x1 = vadd_u8(string.x1, temp);

    vst1_u8((uint8_t *) buffer, string.x1); // Output the string

#elif defined(USE_SIMD) && (defined(__x86_64__) || defined(_M_X64))

    // Intel SSE Intrinsics

    __m128i string, temp, mask;

#ifdef _MSC_VER
    value  = _byteswap_ulong(value);        // Reverse bytes to match string
#else
    value  = __builtin_bswap32(value);
#endif

    string = _mm_cvtsi32_si128(value);

    mask   = _mm_loadu_si32(&lo);           // Set temp   to the HO nibbles
    temp   = _mm_srli_epi32(string, 4);     // and string to the LO nibbles
    temp   = _mm_and_si128(temp,   mask);
    string = _mm_and_si128(string, mask);

    string = _mm_unpacklo_epi8(temp, string); // Interleave the HO and LO nibbles
    
    temp   = _mm_loadu_si64((__m128i *) ascii0); // Convert binary to ascii,
    string = _mm_or_si128(string, temp);         // note only 0-9 will be correct

    temp   = _mm_loadu_si64((__m128i *) ascii9); // Determine which bytes
    mask   = _mm_cmpgt_epi8(string, temp);       // should be A-F
    
    temp   = _mm_loadu_si64((__m128i *) af); // Update bytes that should be A-F
    temp   = _mm_and_si128(temp, mask);
    string = _mm_add_epi8(string, temp);

    _mm_storeu_si64(buffer, string);        // Output the string

#else
    
    // Default C implementation
    
    buffer[0] = lookup[(value >> 28) & 0x0F];
    buffer[1] = lookup[(value >> 24) & 0x0F];
    buffer[2] = lookup[(value >> 20) & 0x0F];
    buffer[3] = lookup[(value >> 16) & 0x0F];
    buffer[4] = lookup[(value >> 12) & 0x0F];
    buffer[5] = lookup[(value >>  8) & 0x0F];
    buffer[6] = lookup[(value >>  4) & 0x0F];
    buffer[7] = lookup[ value        & 0x0F];
#endif

    buffer[8] = 0;

    return buffer;
}



//----------------------------------------------------------------------------

const char *u16ToHexStr(char *buffer, uint16_t value) {
#if defined(USE_SIMD) && defined(__aarch64__)

    // ARM NEON 64 Intrinsics

    uint8x8_t string, temp, clear;

    value  = __builtin_bswap16(value);      // Reverse bytes to match string
    string = vld1_u8((uint8_t *) &value);
    
    temp   = vshr_n_u8(string, 4);          // Set temp   to the HO nibbles
    clear  = vld1_dup_u8(&ho);              // and string to the LO nibbles
    string = vbic_u8(string, clear);
    
    string = vzip1_u8(temp, string);        // Interleave the HO and LO nibbles
    
    temp   = vld1_dup_u8(ascii0);           // Convert binary to ascii,
    string = vorr_u8(string, temp);         // note only 0-9 will be correct
    
    temp   = vld1_dup_u8(ascii9);           // Determine which bytes
    temp   = vcgt_u8(string, temp);         // should be A-F
    
    clear  = vld1_dup_u8(&invaf);           // Update bytes that should be A-F
    temp   = vbic_u8(temp, clear);
    string = vadd_u8(string, temp);

    *(uint32_t *) buffer = vget_lane_u32(vreinterpret_u32_u8(string), 0); // Output the string

#elif defined(USE_SIMD) && defined(__arm__)
    
    // ARM NEON 32 Intrinsics

    union uint8x8   string;
    uint8x8_t       temp, clear;

    value     = __builtin_bswap16(value);   // Reverse bytes to match string
    string.x1 = vld1_u8((uint8_t *) &value);
    
    temp      = vshr_n_u8(string.x1, 4);    // Set temp   to the HO nibbles
    clear     = vld1_dup_u8(&ho);           // and string to the LO nibbles
    string.x1 = vbic_u8(string.x1, clear);
    
    string.x2 = vzip_u8(temp, string.x1);   // Interleave the HO and LO nibbles
    
    temp      = vld1_dup_u8(ascii0);        // Convert binary to ascii,
    string.x1 = vorr_u8(string.x1, temp);   // note only 0-9 will be correct
    
    temp      = vld1_dup_u8(ascii9);        // Determine which bytes
    temp      = vcgt_u8(string.x1, temp);   // should be A-F
    
    clear     = vld1_dup_u8(&invaf);        // Update bytes that should be A-F
    temp      = vbic_u8(temp, clear);
    string.x1 = vadd_u8(string.x1, temp);

    *(uint32_t *) buffer = vget_lane_u32(vreinterpret_u32_u8(string.x1), 0); // Output the string

#elif defined(USE_SIMD) && (defined(__x86_64__) || defined(_M_X64))

    // Intel SSE Intrinsics

    __m128i string, temp, mask;

#ifdef _MSC_VER
    value  = _byteswap_ushort(value);       // Reverse bytes to match string
#else
    value  = __builtin_bswap16(value);
#endif

    string = _mm_cvtsi32_si128((uint32_t) value);

    mask   = _mm_loadu_si16(&lo);           // Set temp   to the HO nibbles
    temp   = _mm_srli_epi16(string, 4);     // and string to the LO nibbles
    temp   = _mm_and_si128(temp,   mask);
    string = _mm_and_si128(string, mask);

    string = _mm_unpacklo_epi8(temp, string); // Interleave the HO and LO nibbles
    
    temp   = _mm_loadu_si32((__m128i *) ascii0); // Convert binary to ascii,
    string = _mm_or_si128(string, temp);         // note only 0-9 will be correct

    temp   = _mm_loadu_si32((__m128i *) ascii9); // Determine which bytes
    mask   = _mm_cmpgt_epi8(string, temp);       // should be A-F
    
    temp   = _mm_loadu_si32((__m128i *) af); // Update bytes that should be A-F
    temp   = _mm_and_si128(temp, mask);
    string = _mm_add_epi8(string, temp);

    _mm_storeu_si32(buffer, string);        // Output the string

#else
    
    // Default C implementation
    
    buffer[0] = lookup[(value >> 12) & 0x0F];
    buffer[1] = lookup[(value >>  8) & 0x0F];
    buffer[2] = lookup[(value >>  4) & 0x0F];
    buffer[3] = lookup[ value        & 0x0F];
    
#endif

    buffer[4] = 0;

    return buffer;
}



//----------------------------------------------------------------------------
// For the smaller sizes just use a default C implementation

const char *u8ToHexStr(char *buffer, uint8_t value) {
    buffer[0] = lookup[(value >>  4) & 0x0F];
    buffer[1] = lookup[ value        & 0x0F];
    buffer[2] = 0;

    return buffer;
}

const char *u4ToHexStr(char *buffer, uint8_t value) {
    buffer[0] = lookup[value & 0x0F];
    buffer[1] = 0;

    return buffer;
}

