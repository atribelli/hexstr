// hexstr-test.cpp

#include <iostream>
#include <iomanip>
#include <cstring>
#include <cinttypes>

using namespace std;

#include "hexstr-test.h"
#include "hexstr.h"



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
    snprintf(bufferPrint, sizeof(bufferPrint), "%" PRIX64, u64);
    u64ToHexStr(bufferDecStr, u64);
    removeLeadingZeros(bufferDecStr);
    
    if (strcmp(bufferPrint, bufferDecStr) != 0) {
        printf("%s i: %d value: 0x%" PRIX64 " printf: \"%s\" decstr: \"%s\"\n",
               lablel, i, u64, bufferPrint, bufferDecStr);
    }
}

// Test u32
void test_u32(const char *lablel, int i, uint32_t u32) {
    snprintf(bufferPrint, sizeof(bufferPrint), "%" PRIX32, u32);
    u32ToHexStr(bufferDecStr, u32);
    removeLeadingZeros(bufferDecStr);
    
    if (strcmp(bufferPrint, bufferDecStr) != 0) {
        printf("%s i: %d value: 0x%" PRIX32 " printf: \"%s\" decstr: \"%s\"\n",
               lablel, i, u32, bufferPrint, bufferDecStr);
    }
}

void test (void) {
    uint64_t u64;
    uint32_t u32;

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

    cout << "Tests complete" << endl;
}
