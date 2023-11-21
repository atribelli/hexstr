// main.cpp

#include <iostream>
#include <iomanip>
#include <chrono>

using namespace std;
using namespace std::chrono;

#include "hexstr.h"

int main (int argc, char *argv[]) {
    alignas(128) char        buffer1[32];
    alignas(128) char        buffer2[32];
    steady_clock::time_point start;
    duration<double>         elapsed64, elapsed32,
                             elapsed16, elapsed8, elapsed4;
    uint64_t                 value1     = 0xfedcba9876543210;
    uint64_t                 value2     = 0x0123456789abcdef;
    uint64_t                 iterations = 100000000;

    // Make sure we have the proper level of CPU functionality

#if   defined(__aarch64__)
#elif defined(__x86_64__)
    if (! (__builtin_cpu_supports("ssse3"))) {
        cout << "Requires SSSE3 support" << endl;
        return 1;
    }
    if (! (__builtin_cpu_supports("avx"))) {
        cout << "Requires AVX support" << endl;
        return 1;
    }
#else
#endif

    // Do the timing before any output to minimize background activity
    
    start = steady_clock::now();
    for (uint64_t i = 0; i < iterations; ++i) {
        u64ToHexStr(buffer1, value1);
    }
    elapsed64 = steady_clock::now() - start;

    start = steady_clock::now();
    for (uint64_t i = 0; i < iterations; ++i) {
        u32ToHexStr(buffer1, value1);
    }
    elapsed32 = steady_clock::now() - start;

    start = steady_clock::now();
    for (uint64_t i = 0; i < iterations; ++i) {
        u16ToHexStr(buffer1, value1);
    }
    elapsed16 = steady_clock::now() - start;

    start = steady_clock::now();
    for (uint64_t i = 0; i < iterations; ++i) {
        u8ToHexStr(buffer1, value1);
    }
    elapsed8 = steady_clock::now() - start;

    start = steady_clock::now();
    for (uint64_t i = 0; i < iterations; ++i) {
        u4ToHexStr(buffer1, value1);
    }
    elapsed4 = steady_clock::now() - start;

    // Show the user the results
    
    cout << u64ToHexStr(buffer1, value1) << " "
         << u64ToHexStr(buffer2, value2) << endl
         << u32ToHexStr(buffer1, value1) << " "
         << u32ToHexStr(buffer2, value2) << endl
         << u16ToHexStr(buffer1, value1) << " "
         << u16ToHexStr(buffer2, value2) << endl
         <<  u8ToHexStr(buffer1, value1) << " "
         <<  u8ToHexStr(buffer2, value2) << endl
         <<  u4ToHexStr(buffer1, value1) << " "
         <<  u4ToHexStr(buffer2, value2) << endl;
    cout << flush;

    cout << fixed
         << setprecision(2)
         << "u64: " << elapsed64.count() << " sec" << endl
         << "u32: " << elapsed32.count() << " sec" << endl
         << "u16: " << elapsed16.count() << " sec" << endl
         << "u8:  " << elapsed8.count()  << " sec" << endl
         << "u4:  " << elapsed4.count()  << " sec" << endl;

    return 0;
}
