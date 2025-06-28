// decstr-intrin.c
//
// Convert values of various sizes to zero terminated decimal strings.
//     u64ToDecStr   64-bit unsigned quad word
//     s64ToDecStr   64-bit signed quad word
//     u32ToDecStr   32-bit unsigned quad word
//     s32ToDecStr   32-bit signed quad word

#include <stdint.h>
#include <stdalign.h>

#if   defined(USE_SIMD) && defined(__aarch64__)

#include <arm_neon.h>

#elif defined(USE_SIMD) && defined(__arm__)

#include <arm_neon.h>

#elif defined(USE_SIMD) && (defined(__x86_64__) || defined(_M_X64))

#include <immintrin.h>

#endif

#include "decstr.h"



// 11 digit 64-bit integer divisor table.
// Handles the first 11 digits of a 20 digit value.
alignas(32)
uint64_t ten19u[11] = { 10000000000000000000ULL,
                        1000000000000000000ULL,
                        100000000000000000ULL,
                        10000000000000000ULL,
                        1000000000000000ULL,
                        100000000000000ULL,
                        10000000000000ULL,
                        1000000000000ULL,
                        100000000000ULL,
                        10000000000ULL,
                        1000000000ULL
};

// 9 digit 32-bit integer divisor table.
// Handles the last 9 digits of a 20 digit value.
alignas(32)
uint32_t ten8u[9] = {   100000000U,
                        10000000U,
                        1000000U,
                        100000U,
                        10000U,
                        1000U,
                        100U,
                        10U,
                        1U
};

// 15 digit floating point divisor table
alignas(32)
double ten14d[16] = {   100000000000000.0,  // Limitted to 52-bit values
                        10000000000000.0,
                        1000000000000.0,
                        100000000000.0,
                        10000000000.0,
                        1000000000.0,
                        100000000.0,
                        10000000.0,
                        1000000.0,
                        100000.0,
                        10000.0,
                        1000.0,
                        100.0,
                        10.0,
                        1.0,
                        1.0                 // For disregarded lane
};

// 10 digit 32-bit integer divisor table
alignas(32)
uint32_t ten9u[10] = {  1000000000U,
                        100000000U,
                        10000000U,
                        1000000U,
                        100000U,
                        10000U,
                        1000U,
                        100U,
                        10U,
                        1U
};

// 10 digit floating point divisor table
alignas(32)
double ten9d[10] = {    1000000000.0,
                        100000000.0,
                        10000000.0,
                        1000000.0,
                        100000.0,
                        10000.0,
                        1000.0,
                        100.0,
                        10.0,
                        1.0
};

alignas(32)
double tend[4] = {      10.0, 10.0, 10.0, 10.0
};

alignas(32)
uint8_t ascii0[16] = {  '0', '0', '0', '0', '0', '0', '0', '0',
                        '0', '0', '0', '0', '0', '0', '0', '0'
};



//----------------------------------------------------------------------------
// Convert value to zero terminated decimal string.
// Arguments:
//     buffer   Pointer to a buffer assumed to be large enough for
//              string and null terminator, and assumed to be aligned to an
//              even address.
//     value    Numeric value to convert.
// Return:
//              Pointer to buffer

const char *s64ToDecStr(char *buffer, int64_t value) {
    if (value < 0) {
        // Output sign and pass absolute value to unsigned function
        buffer[0] = '-';
        return u64ToDecStr(buffer + 1, (uint64_t) (-value));
    }
    else {
        // Continue using unsigned code
        return u64ToDecStr(buffer, (uint64_t) value);
    }
}

const char *u64ToDecStr(char *buffer, uint64_t value) {
#if defined(USE_SIMD) && defined(__aarch64__)
    
    // ARM NEON 64 Intrinsics

    buffer[0] = 0;

#elif defined(USE_SIMD) && defined(__arm__)
    
    // ARM NEON 32 Intrinsics

    buffer[0] = 0;

#elif defined(USE_SIMD) && (defined(__x86_64__) || defined(_M_X64))
    
    // Intel SSE Intrinsics

    // First 5 digits, which require 64-bits
    int i = 0;
    while (i < 5) {
        uint64_t divisor = ten19u[i];
        
        buffer[i++]  = ((uint8_t) (value / divisor)) + '0';
        value       %= divisor;
    }
    
    // Next 14 digits, which will fit in 52-bits
    __m128d values, tens, quotients, mod10s, mul10s, divisors;
    double  val;

    val    = (double) value;
    values = _mm_load_pd1(&val);
    tens   = _mm_load_pd(tend);
    int j  = 0;
    while (i < 19) {
        divisors  = _mm_load_pd(&ten14d[j]);
        j        += 2;

        quotients = _mm_div_pd(values, divisors);   // Divide by powers of 10
        quotients = _mm_floor_pd(quotients);        // Truncate for quotient
        mod10s    = _mm_div_pd(quotients, tens);    // Calculate mod 10
        mod10s    = _mm_floor_pd(mod10s);
        mul10s    = _mm_mul_pd(mod10s, tens);
        mod10s    = _mm_sub_pd(quotients, mul10s);

        buffer[i++]  = ((uint8_t) _mm_cvtsd_si32(mod10s)) + '0';
        mod10s       = _mm_shuffle_pd(mod10s, mod10s, 1);
        buffer[i++]  = ((uint8_t) _mm_cvtsd_si32(mod10s)) + '0';
    }

    // Final digit is calculated as a scalar
    divisors  = _mm_load_sd(&ten14d[j]);
    quotients = _mm_div_sd(values, divisors);
    quotients = _mm_floor_sd(quotients, quotients);
    mod10s    = _mm_div_sd(quotients, tens);
    mod10s    = _mm_floor_sd(mod10s, mod10s);
    mul10s    = _mm_mul_sd(mod10s, tens);
    mod10s    = _mm_sub_sd(quotients, mul10s);
    buffer[i] = ((uint8_t) _mm_cvtsd_si32(mod10s)) + '0';

#else
    
    // Default C implementation

    // First 11 digits, which require 64-bits
    int i = 0;
    while (i < 11) {
        uint64_t divisor = ten19u[i];
        
        buffer[i++]  = ((uint8_t) (value / divisor)) + '0';
        value       %= divisor;
    }
    
    // Next 8 digits, which will fit in 32-bits
    uint32_t val = (uint32_t) value;
    int      j       = 0;
    while (i < 19) {
        uint32_t divisor = ten8u[j++];
        
        buffer[i++]  = ((uint8_t) (val / divisor)) + '0';
        val         %= divisor;
    }

    // Final digit does not need remainder calculation
    buffer[i] = ((uint8_t) (val / ten8u[j])) + '0';


#endif

    buffer[20] = 0;

    return (const char *) ((uint64_t) buffer & -2);
}



//----------------------------------------------------------------------------

const char *s32ToDecStr(char *buffer, int32_t value) {
    if (value < 0) {
        // Output sign and pass absolute value to unsigned function
        buffer[0] = '-';
        return u32ToDecStr(buffer + 1, (uint32_t) (-value));
    }
    else {
        // Continue using unsigned code
        return u32ToDecStr(buffer, (uint32_t) value);
    }
}

const char *u32ToDecStr(char *buffer, uint32_t value) {
#if defined(USE_SIMD) && defined(__aarch64__)

    // ARM NEON 64 Intrinsics

    buffer[0] = 0;

#elif defined(USE_SIMD) && defined(__arm__)
    
    // ARM NEON 32 Intrinsics

    buffer[0] = 0;

#elif defined(USE_SIMD) && (defined(__x86_64__) || defined(_M_X64))

    // Intel SSE Intrinsics

    // All 10 digits
    __m128d values, tens, quotients, mod10s, mul10s, divisors;
    double  val;

    val    = (double) value;
    values = _mm_load_pd1(&val);
    tens   = _mm_load_pd(tend);
    int i  = 0;
    while (i < 10) {
        divisors  = _mm_load_pd(&ten9d[i]);

        quotients = _mm_div_pd(values, divisors);   // Divide by powers of 10
        quotients = _mm_floor_pd(quotients);        // Truncate for quotient
        mod10s    = _mm_div_pd(quotients, tens);    // Calculate mod 10
        mod10s    = _mm_floor_pd(mod10s);
        mul10s    = _mm_mul_pd(mod10s, tens);
        mod10s    = _mm_sub_pd(quotients, mul10s);

        buffer[i++]  = ((uint8_t) _mm_cvtsd_si32(mod10s)) + '0';
        mod10s       = _mm_shuffle_pd(mod10s, mod10s, 1);
        buffer[i++]  = ((uint8_t) _mm_cvtsd_si32(mod10s)) + '0';
    }

#else
    
    // Default C implementation
    
    // First 9 digits
    int i = 0;
    while (i < 9) {
        uint32_t divisor = ten9u[i];

        buffer[i++]  = (uint8_t) (value / divisor) + '0';
        value       %= divisor;
    }

    // Final digit does not need remainder calculation
    buffer[i] = (uint8_t) (value / ten9u[i]) + '0';
    
#endif

    buffer[10] = 0;

    return (const char *) ((uint64_t) buffer & -2);
}
