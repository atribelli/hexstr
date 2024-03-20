// cpuinfo.cpp
// Assuming C++17

#include <cstdint>

#if defined(__x86_64__)     // 64-bit Intel macOS or Linux
#include <cpuid.h>
#elif defined(_M_X64)       // 64-bit Intel Windows
#include <intrin.h>
#endif

#include "cpuinfo.h"



// -------------------------------------------------------------------------
// Return values from the cpuid instruction

#if defined(__x86_64__)     // 64-bit Intel macOS or Linux

uint32_t eax, ebx, ecx, edx;

#elif defined(_M_X64)       // 64-bit Intel Windows

union {
    struct {
        uint32_t eax, ebx, ecx, edx;
    };
    int32_t regs[4];
} cpuid;

#endif

// -------------------------------------------------------------------------
// Make sure we have the proper level of CPU functionality

bool is_cpu_gen_4(void) {
    // Intel 4th gen (Haswell)
    // https://www.intel.com/content/dam/develop/external/us/en/documents/how-to-detect-new-instruction-support-in-the-4th-generation-intel-core-processor-family.pdf

#if defined(__x86_64__)     // 64-bit Intel macOS or Linux
    
    // Check level of CPUID support
    if (! __get_cpuid(0, &eax, &ebx, &ecx, &edx))
        return false;
    if (eax < 7)
        return false;
    if (! __get_cpuid(0x80000000, &eax, &ebx, &ecx, &edx))
        return false;
    if (eax < 0x80000001)
        return false;

    // EAX 1 ECX 0
    if (! __get_cpuid_count(1, 0, &eax, &ebx, &ecx, &edx))
        return false;
    
    // FMA
    if ((ecx & (1 << 12)) == 0)
        return false;

    // MOVBE
    if ((ecx & (1 << 22)) == 0)
        return false;

    // OSXSAVE
    if ((ecx & (1 << 27)) == 0)
        return false;

    // EAX 7 ECX 0
    if (! __get_cpuid_count(7, 0, &eax, &ebx, &ecx, &edx))
        return false;

    // AVX2
    if ((ebx & (1 << 5)) == 0)
        return false;

    // BMI
    if ((ebx & (1 << 3)) == 0)
        return false;
    if ((ebx & (1 << 8)) == 0)
        return false;

    // EAX 0x80000001 ECX 0
    if (! __get_cpuid_count(0x80000001, 0, &eax, &ebx, &ecx, &edx))
        return false;

    // LZCNT
    if ((ecx & (1 << 5)) == 0)
        return false;

#elif defined(_M_X64)       // 64-bit Intel Windows

    // Check level of CPUID support
    __cpuid(cpuid.regs, 0);
    if (cpuid.eax < 7)
        return false;
    __cpuid(cpuid.regs, 0x80000000);
    if (cpuid.eax < 0x80000001)
        return false;

    // EAX 1 ECX 0
    __cpuidex(cpuid.regs, 1, 0);

    // FMA
    if ((cpuid.ecx & (1 << 12)) == 0)
        return false;

    // MOVBE
    if ((cpuid.ecx & (1 << 22)) == 0)
        return false;

    // OSXSAVE
    if ((cpuid.ecx & (1 << 27)) == 0)
        return false;

    // EAX 7 ECX 0
    __cpuidex(cpuid.regs, 7, 0);

    // AVX2
    if ((cpuid.ebx & (1 << 5)) == 0)
        return false;

    // BMI
    if ((cpuid.ebx & (1 << 3)) == 0)
        return false;
    if ((cpuid.ebx & (1 << 8)) == 0)
        return false;

    // EAX 0x80000001 ECX 0
    __cpuidex(cpuid.regs, 0x80000001, 0);

    // LZCNT
    if ((cpuid.ecx & (1 << 5)) == 0)
        return false;

#endif

        return true;
}



// -------------------------------------------------------------------------
// Identify the CPU

bool get_cpu_vendor(char *buffer, size_t len) {
    bool valid = false;
    
    if (buffer != nullptr && len >= 13) {

#if defined(__x86_64__)     // 64-bit Intel macOS or Linux
        
        if (__get_cpuid (0, &eax, &ebx, &ecx, &edx)) {
            *((uint32_t *) &buffer[ 0]) = ebx;
            *((uint32_t *) &buffer[ 4]) = edx;
            *((uint32_t *) &buffer[ 8]) = ecx;
                            buffer[12]  = 0;
            
            valid = true;
        }
    
#elif defined(_M_X64)       // 64-bit Intel Windows

        __cpuid(cpuid.regs, 0);
        *((uint32_t *) &buffer[ 0]) = cpuid.ebx;
        *((uint32_t *) &buffer[ 4]) = cpuid.edx;
        *((uint32_t *) &buffer[ 8]) = cpuid.ecx;
                        buffer[12]  = 0;
        
        valid = true;

#endif
        
    }

    return valid;
}

bool get_cpu_brand(char *buffer, size_t len) {
    bool valid = false;
    
    if (buffer != nullptr && len >= 49) {

#if defined(__x86_64__)     // 64-bit Intel macOS or Linux

        if (   __get_cpuid (0x80000000, &eax, &ebx, &ecx, &edx)
            && ((eax & 0x80000000) && (eax >= 0x80000004))) {
            __get_cpuid (0x80000002, &eax, &ebx, &ecx, &edx);
            *((uint32_t *) &buffer[ 0]) = eax;
            *((uint32_t *) &buffer[ 4]) = ebx;
            *((uint32_t *) &buffer[ 8]) = ecx;
            *((uint32_t *) &buffer[12]) = edx;
            __get_cpuid (0x80000003, &eax, &ebx, &ecx, &edx);
            *((uint32_t *) &buffer[16]) = eax;
            *((uint32_t *) &buffer[20]) = ebx;
            *((uint32_t *) &buffer[24]) = ecx;
            *((uint32_t *) &buffer[28]) = edx;
            __get_cpuid (0x80000004, &eax, &ebx, &ecx, &edx);
            *((uint32_t *) &buffer[32]) = eax;
            *((uint32_t *) &buffer[36]) = ebx;
            *((uint32_t *) &buffer[40]) = ecx;
            *((uint32_t *) &buffer[44]) = edx;
                            buffer[48]  = 0;
            
            valid = true;
        }

#elif defined(_M_X64)       // 64-bit Intel Windows

        __cpuid(cpuid.regs, 0x80000000);
        if ((cpuid.eax & 0x80000000) && (cpuid.eax >= 0x80000004)) {
            __cpuid(cpuid.regs, 0x80000002);
            *((uint32_t *) &buffer[ 0]) = cpuid.eax;
            *((uint32_t *) &buffer[ 4]) = cpuid.ebx;
            *((uint32_t *) &buffer[ 8]) = cpuid.ecx;
            *((uint32_t *) &buffer[12]) = cpuid.edx;
            __cpuid(cpuid.regs, 0x80000003);
            *((uint32_t *) &buffer[16]) = cpuid.eax;
            *((uint32_t *) &buffer[20]) = cpuid.ebx;
            *((uint32_t *) &buffer[24]) = cpuid.ecx;
            *((uint32_t *) &buffer[28]) = cpuid.edx;
            __cpuid(cpuid.regs, 0x80000004);
            *((uint32_t *) &buffer[32]) = cpuid.eax;
            *((uint32_t *) &buffer[36]) = cpuid.ebx;
            *((uint32_t *) &buffer[40]) = cpuid.ecx;
            *((uint32_t *) &buffer[44]) = cpuid.edx;
                            buffer[48]  = 0;
            
            valid = true;
        }

#endif
        
    }

    return valid;
}
