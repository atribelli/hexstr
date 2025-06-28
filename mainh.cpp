// mainh.cpp

#include <iostream>
#include <iomanip>
#include <chrono>
#include <algorithm>
#include <climits>
#include <cinttypes>

using namespace std;
using namespace std::chrono;

#include "cpuinfo.h"
#include "timer.h"
#include "hexstr-test.h"
#include "hexstr.h"


// Align for 256-bit register
const int alignment = 256 / 8;

int main (int argc, char *argv[]) {
    alignas(alignment) char buffer0[32];
    alignas(alignment) char buffer1[32];
    alignas(alignment) char buffer2[32];
    timer<float, nano>      nanoseconds;
    float                   elapsedPrintf,
                            elapsed,   elapsed64, elapsed32,
                            elapsed16, elapsed8,  elapsed4;
    uint64_t                value1     = 0xfedcba9876543210,
                            value2     = 0x0123456789abcdef;
    uint32_t                iterations = 100'000'000,
                            scale      = 1;

    // -------------------------------------------------------------------------
    // Do the timing before any output to minimize background activity
    
    // Use volatile to prevent optimizer removing code
    volatile int no_opt_i;

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        snprintf(buffer0, sizeof(buffer0), "%" PRIX64, value1);
    }
    elapsedPrintf = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u64ToHexStr(buffer1, value1);
    }
    elapsed64 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u32ToHexStr(buffer1, value1);
    }
    elapsed32 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u16ToHexStr(buffer1, value1);
    }
    elapsed16 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u8ToHexStr(buffer1, value1);
    }
    elapsed8 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u4ToHexStr(buffer1, value1);
    }
    elapsed4 = nanoseconds.elapsed() / float(iterations);

    // -------------------------------------------------------------------------
    // Identify the CPU

    char buffer[2048];
    bool success = false;

    if (get_cpu_vendor(buffer, sizeof(buffer))) {
        cout << (char *) buffer << " ";
        success = true;
    }
    
    if (get_cpu_brand(buffer, sizeof(buffer))) {
        cout << (char *) buffer << " ";
        success = true;
    }
    
    if (get_cpu_part(buffer, sizeof(buffer))) {
        cout << (char *) buffer << " ";
        success = true;
    }
    
    if (get_cpu_cores(buffer, sizeof(buffer))) {
        cout << (char *) buffer << " ";
        success = true;
    }

    if (success) {
        cout << endl;
    }
    
    if (get_cpu_features(buffer, sizeof(buffer))) {
        cout << (char *) buffer << endl;
    }

    // -------------------------------------------------------------------------
    // Show the user the testing results

    test();

    // Show the user the timing results

    snprintf(buffer0, sizeof(buffer0), "%" PRIX64, value1);

    cout.imbue(std::locale(""));
    cout << buffer0                                << endl
         << u64ToHexStr(buffer1, value1)           << " "
         << u64ToHexStr(buffer2, value2)           << endl
         << u32ToHexStr(buffer1, value1)           << " "
         << u32ToHexStr(buffer2, value2)           << endl
         << u16ToHexStr(buffer1, value1)           << " "
         << u16ToHexStr(buffer2, value2)           << endl
         <<  u8ToHexStr(buffer1, value1)           << " "
         <<  u8ToHexStr(buffer2, value2)           << endl
         <<  u4ToHexStr(buffer1, value1)           << " "
         <<  u4ToHexStr(buffer2, value2)           << endl
         << "iterations: " << iterations           << endl
         << fixed << setprecision(2)
         << "snprintf: " << elapsedPrintf << " ns" << endl
         << "u64:      " << elapsed64     << " ns" << endl
         << "u32:      " << elapsed32     << " ns" << endl
         << "u16:      " << elapsed16     << " ns" << endl
         << "u8:       " << elapsed8      << " ns" << endl
         << "u4:       " << elapsed4      << " ns" << endl;

    return 0;
}
