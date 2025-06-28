// maind.cpp

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
#include "decstr-test.h"
#include "decstr.h"


// Align for 256-bit register
const int alignment = 256 / 8;

int main (int argc, char *argv[]) {
    alignas(alignment) char buffer64[32];
    alignas(alignment) char buffer32[32];
    alignas(alignment) char buffer1[32];
    alignas(alignment) char buffer2[32];
    alignas(alignment) char buffer3[32];
    timer<float, nano>      nanoseconds;
    float                   elapsedPrintf64, elapsedPrintf32,
                            elapsed1u64, elapsed2s64, elapsed3s64,
                            elapsed1u32, elapsed2s32, elapsed3s32;
    uint64_t                value1u64 = 18'446'744'073'709'551'615u;
    int64_t                 value2s64 =  9'223'372'036'854'775'807u,
                            value3s64 = -9'223'372'036'854'775'807;
    uint32_t                value1u32 =              4'294'967'295u;
    int32_t                 value2s32 =              2'147'483'647u,
                            value3s32 =             -2'147'483'647;
    uint32_t                iterations = 10'000'000,
                            scale      = 1;

    // -------------------------------------------------------------------------
    // Do the timing before any output to minimize background activity
    
    // Use volatile to prevent optimizer removing code
    volatile int no_opt_i;

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        snprintf(buffer64, sizeof(buffer64), "%" PRIu64, value3s64);
    }
    elapsedPrintf64 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u64ToDecStr(buffer1, value1u64);
    }
    elapsed1u64 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u64ToDecStr(buffer2, value2s64);
    }
    elapsed2s64 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        s64ToDecStr(buffer3, value3s64);
    }
    elapsed3s64 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        snprintf(buffer32, sizeof(buffer32), "%u", value3s32);
    }
    elapsedPrintf32 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u32ToDecStr(buffer1, value1u32);
    }
    elapsed1u32 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        u32ToDecStr(buffer2, value2s32);
    }
    elapsed2s32 = nanoseconds.elapsed() / float(iterations);

    nanoseconds.start();
    for (no_opt_i = 0; no_opt_i < iterations; ++no_opt_i) {
        s32ToDecStr(buffer3, value3s32);
    }
    elapsed3s32 = nanoseconds.elapsed() / float(iterations);

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

    snprintf(buffer64, sizeof(buffer64), "%" PRIu64, value1u64);
    snprintf(buffer32, sizeof(buffer32), "%u",       value1u32);

    cout.imbue(std::locale(""));
    cout << buffer64                                   << endl
         << u64ToDecStr (buffer1, value1u64)           << " "
         << u64ToDecStr (buffer2, value2s64)           << " "
         << s64ToDecStr (buffer3, value3s64)           << endl
         << buffer32                                   << endl
         << u32ToDecStr (buffer1, value1u32)           << " "
         << u32ToDecStr (buffer2, value2s32)           << " "
         << s32ToDecStr (buffer3, value3s32)           << endl
         << "iterations: " << iterations               << endl
         << fixed << setprecision(2)
         << "snprintf64: " << elapsedPrintf64 << " ns" << endl
         << "u64:        " << elapsed1u64     << " ns" << endl
         << "s64:        " << elapsed2s64     << " ns" << endl
         << "s64:        " << elapsed3s64     << " ns" << endl
         << "snprintf32: " << elapsedPrintf32 << " ns" << endl
         << "u32:        " << elapsed1u32     << " ns" << endl
         << "s32:        " << elapsed2s32     << " ns" << endl
         << "s32:        " << elapsed3s32     << " ns" << endl;

    return 0;
}
