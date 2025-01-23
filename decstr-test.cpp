// decstr-test.cpp

#include <iostream>
#include <iomanip>
#include <cstring>
#include <cinttypes>

using namespace std;

#include "decstr-test.h"
#include "decstr.h"



// Number of elements in an array
template <typename T, size_t N>
constexpr size_t numElements(const T(&)[N]) {
    return N;
}

// Align for 256-bit register
const int alignment = 256 / 8;


// Remove leading zeros
void removeLeadingZeros(char *buffer) {
    char *start = buffer,
         *non0  = start;
    
    if (*start == '-') {
        non0 = ++start;
    }
    
    // SKip any zero except the final digit
    while (*non0 != 0 && *non0 == '0' && *(non0 + 1) != 0) {
        ++non0;
    }

    // No leading zeros
    if (start == non0) {
        return;
    }

    do {
        *start++ = *non0++;
    } while (*start != 0);
}

alignas(alignment) char bufferPrint[32];
alignas(alignment) char bufferDecStr[32];

// Test u64
void test_u64(const char *lablel, int i, uint64_t u64) {
    snprintf(bufferPrint, sizeof(bufferPrint), "%" PRIu64, u64);
    u64ToDecStr(bufferDecStr, u64);
    removeLeadingZeros(bufferDecStr);
    
    if (strcmp(bufferPrint, bufferDecStr) != 0) {
        printf("%s i: %d value: 0x%" PRIX64 " printf: \"%s\" decstr: \"%s\"\n",
               lablel, i, u64, bufferPrint, bufferDecStr);
    }
}

// Test u32
void test_u32(const char *lablel, int i, uint32_t u32) {
    snprintf(bufferPrint, sizeof(bufferPrint), "%" PRIu32, u32);
    u32ToDecStr(bufferDecStr, u32);
    removeLeadingZeros(bufferDecStr);
    
    if (strcmp(bufferPrint, bufferDecStr) != 0) {
        printf("%s i: %d value: 0x%" PRIX32 " printf: \"%s\" decstr: \"%s\"\n",
               lablel, i, u32, bufferPrint, bufferDecStr);
    }
}

// Test s64
void test_s64(const char *lablel, int i, int64_t s64) {
    snprintf(bufferPrint, sizeof(bufferPrint), "%" PRId64, s64);
    s64ToDecStr(bufferDecStr, s64);
    removeLeadingZeros(bufferDecStr);
    
    if (strcmp(bufferPrint, bufferDecStr) != 0) {
        printf("%s i: %d value: 0x%" PRIX64 " printf: \"%s\" decstr: \"%s\"\n",
               lablel, i, s64, bufferPrint, bufferDecStr);
    }
}

// Test s32
void test_s32(const char *lablel, int i, int32_t s32) {
    snprintf(bufferPrint, sizeof(bufferPrint), "%" PRId32, s32);
    s32ToDecStr(bufferDecStr, s32);
    removeLeadingZeros(bufferDecStr);
    
    if (strcmp(bufferPrint, bufferDecStr) != 0) {
        printf("%s i: %d value: 0x%" PRIX32 " printf: \"%s\" decstr: \"%s\"\n",
               lablel, i, s32, bufferPrint, bufferDecStr);
    }
}

void test (void) {
    uint64_t u64;
    int64_t  s64;
    uint32_t u32;
    int32_t  s32;

    // -------------------------------------------------------------------------
    // Test powers of 2, +/-

    u64 = 0;
    for (int i = 0; i < 65; ++i) {
        test_u64("u64 2^i - 1", i, u64 - 1u);
        test_u64("u64 2^i    ", i, u64);
        test_u64("u64 2^i + 1", i, u64 + 1u);
        
        u64 = (u64 << 1) | 1;
    }

    u32 = 0;
    for (int i = 0; i < 33; ++i) {
        test_u32("u32 2^i - 1", i, u32 - 1u);
        test_u32("u32 2^i    ", i, u32);
        test_u32("u32 2^i + 1", i, u32 + 1u);
        
        u32 = (u32 << 1) | 1;
    }

    s64 = 0;
    for (int i = 0; i < 65; ++i) {
        test_s64("s64 2^i - 1", i, s64 - 1u);
        test_s64("s64 2^i    ", i, s64);
        test_s64("s64 2^i + 1", i, s64 + 1u);
        
        s64 = (s64 << 1) | 1;
    }

    s32 = 0;
    for (int i = 0; i < 33; ++i) {
        test_s32("s32 2^i - 1", i, s32 - 1u);
        test_s32("s32 2^i    ", i, s32);
        test_s32("s32 2^i + 1", i, s32 + 1u);
        
        s32 = (s32 << 1) | 1;
    }

    // -------------------------------------------------------------------------
    // Test powers of 10, +/-

    u64 = 1;
    for (int i = 0; i < 21; ++i) {
        test_u64("u64 10^i - 1", i, u64 - 1u);
        test_u64("u64 10^i    ", i, u64);
        test_u64("u64 10^i + 1", i, u64 + 1u);
        
        u64 *= 10u;
    }

    u32 = 1;
    for (int i = 0; i < 11; ++i) {
        test_u32("u32 10^i - 1", i, u32 - 1u);
        test_u32("u32 10^i    ", i, u32);
        test_u32("u32 10^i + 1", i, u32 + 1u);
        
        u32 *= 10u;
    }

    s64 = -1;
    for (int i = 0; i < 21; ++i) {
        test_s64("s64 10^i - 1", i, s64 - 1u);
        test_s64("s64 10^i    ", i, s64);
        test_s64("s64 10^i + 1", i, s64 + 1u);
                
        s64 *= 10;
    }

    s32 = -1;
    for (int i = 0; i < 11; ++i) {
        test_s32("s32 10^i - 1", i, s32 - 1u);
        test_s32("s32 10^i    ", i, s32);
        test_s32("s32 10^i + 1", i, s32 + 1u);
        
        s32 *= 10;
    }

    cout << "Tests complete" << endl;
}
