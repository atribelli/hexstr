// main.cpp

#include <iostream>
#include <iomanip>
#include <chrono>
#include <algorithm>
#include <climits>

using namespace std;
using namespace std::chrono;

#include "cpuinfo.h"
#include "timer.h"
#include "hexstr.h"


// Align for 256-bit register
const int alignment = 256 / 8;

int main (int argc, char *argv[]) {
    alignas(alignment) char buffer1[32];
    alignas(alignment) char buffer2[32];
    timer<int, milli>       milliseconds;
    float                   elapsed, elapsed64, elapsed32,
                            elapsed16, elapsed8, elapsed4;
    uint64_t                value1     = 0xfedcba9876543210;
    uint64_t                value2     = 0x0123456789abcdef;
    uint32_t                iterations = 100'000'000;
    uint32_t                scale      = 1;

#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    // Make sure we have the proper level of CPU functionality
    if (! is_cpu_gen_4()) {
        cout << "CPU is not x86-64 4th gen compatible" << endl;
        exit(1);
    }

#endif

    // Do the timing before any output to minimize background activity
    
    // Use volatile to prevent optimizer removing code
    volatile int no_opt_i;

    milliseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u64ToHexStr(buffer1, value1);
    }
    elapsed64 = milliseconds.elapsed();

    milliseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u32ToHexStr(buffer1, value1);
    }
    elapsed32 = milliseconds.elapsed();

    milliseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u16ToHexStr(buffer1, value1);
    }
    elapsed16 = milliseconds.elapsed();

    milliseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u8ToHexStr(buffer1, value1);
    }
    elapsed8 = milliseconds.elapsed();

    milliseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u4ToHexStr(buffer1, value1);
    }
    elapsed4 = milliseconds.elapsed();

    // -------------------------------------------------------------------------
    // Identify the CPU

#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    char buffer[64];

    if (get_cpu_brand(buffer, sizeof(buffer))) {
        cout << (char *) buffer << endl;
    }

#endif

    // Show the user the results
    
    int width = 5;
    
    cout.imbue(std::locale(""));
    cout << u64ToHexStr(buffer1, value1) << " "
         << u64ToHexStr(buffer2, value2) << endl
         << u32ToHexStr(buffer1, value1) << " "
         << u32ToHexStr(buffer2, value2) << endl
         << u16ToHexStr(buffer1, value1) << " "
         << u16ToHexStr(buffer2, value2) << endl
         <<  u8ToHexStr(buffer1, value1) << " "
         <<  u8ToHexStr(buffer2, value2) << endl
         <<  u4ToHexStr(buffer1, value1) << " "
         <<  u4ToHexStr(buffer2, value2) << endl
         << "iterations: " << iterations << endl
         << "u64: " << setw(width) << elapsed64 << " ms" << endl
         << "u32: " << setw(width) << elapsed32 << " ms" << endl
         << "u16: " << setw(width) << elapsed16 << " ms" << endl
         << "u8:  " << setw(width) << elapsed8  << " ms" << endl
         << "u4:  " << setw(width) << elapsed4  << " ms" << endl;

    return 0;
}
