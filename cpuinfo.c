// cpuinfo.c

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux
#include <cpuid.h>
#elif defined(_M_X64)                       // 64-bit Intel Windows
#include <intrin.h>
#endif

#include "cpuinfo.h"



// Lets be paranoid about string termination
#define strterm(buf, len) (buf)[(len)       - 1] = 0;
#define bufterm(buf)      (buf)[sizeof(buf) - 1] = 0;



// -------------------------------------------------------------------------
// Return values from the cpuid instruction

#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

union {
    struct {
        uint32_t eax, ebx, ecx, edx;
    };
    int32_t regs[4];
} cpu;

#endif



// -------------------------------------------------------------------------
// Make sure we have the proper level of CPU functionality

bool has_cpuid_level(int value, int level) {
#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux

    // Check level of CPUID support
    if (! __get_cpuid(value, &cpu.eax, &cpu.ebx, &cpu.ecx, &cpu.edx))
        return false;
    if (cpu.eax < level)
        return false;

    return true;

#elif defined(_M_X64)                       // 64-bit Intel Windows

    // Check level of CPUID support
    __cpuid(cpu.regs, value);
    if (cpu.eax < level)
        return false;

    return true;

#endif

    return false;
}


// -------------------------------------------------------------------------
// Make sure we have the proper level of CPU functionality

bool get_cpu_features(int features_eax, int features_ecx) {
#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux

    // Check features

    // EAX 1 ECX 0
    if (! __get_cpuid_count(features_eax, features_ecx,
                            &cpu.eax, &cpu.ebx, &cpu.ecx, &cpu.edx))
        return false;

    return true;

#elif defined(_M_X64)                       // 64-bit Intel Windows

    // Check features

    // EAX 1 ECX 0
    __cpuidex(cpu.regs, features_eax, features_ecx);

    return true;

#endif

    return false;
}



// -------------------------------------------------------------------------
// Check CPU functionality
//
// https://en.wikipedia.org/wiki/AVX-512
// https://en.wikipedia.org/wiki/CPUID

bool cpu_has_avx512_ifma_vbmi(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel
    
    // Check level of CPUID support
    if (! has_cpuid_level(0, 7))
        return false;
    
    // Check features
    
    // EAX 7 ECX 0
    if (! get_cpu_features(7, 0))
        return false;
    
    // AVX-512 Integer Fused Multiply Add
    if ((cpu.ebx & (1 << 21)) == 0)
        return false;

    // AVX-512 Vector Byte Manipulation Instructions
    if ((cpu.ecx & (1 << 1)) == 0)
        return false;
    
    return cpu_has_avx512_f_cd();

#endif

    return false;
}

bool cpu_has_avx512_vl_dq_bw(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel
    
    // Check level of CPUID support
    if (! has_cpuid_level(0, 7))
        return false;
    
    // Check features
    
    // EAX 7 ECX 0
    if (! get_cpu_features(7, 0))
        return false;
    
    // AVX-512 Vector Length Extensions
    if ((cpu.ebx & (1 << 31)) == 0)
        return false;

    // AVX-512 Doubleword and Quadword Instructions
    if ((cpu.ebx & (1 << 17)) == 0)
        return false;
    
    // AVX-512 Byte and Word Instructions
    if ((cpu.ebx & (1 << 30)) == 0)
        return false;
    
    return cpu_has_avx512_f_cd();

#endif

    return false;
}

bool cpu_has_avx512_er_pf(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel
    
    // Check level of CPUID support
    if (! has_cpuid_level(0, 7))
        return false;
    
    // Check features
    
    // EAX 7 ECX 0
    if (! get_cpu_features(7, 0))
        return false;
    
    // AVX-512 Exponential and Reciprocal Instructions
    if ((cpu.ebx & (1 << 27)) == 0)
        return false;
    
    // AVX-512 Prefetch Instructions
    if ((cpu.ebx & (1 << 26)) == 0)
        return false;
    
    return cpu_has_avx512_f_cd();

#endif

    return false;
}

bool cpu_has_avx512_f_cd(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    // Check level of CPUID support
    if (! has_cpuid_level(0, 7))
        return false;

    // Check features

    // EAX 7 ECX 0
    if (! get_cpu_features(7, 0))
        return false;

    // AVX-512 Foundation
    if ((cpu.ebx & (1 << 16)) == 0)
        return false;

    // AVX-512 Conflict Detection Instructions
    if ((cpu.ebx & (1 << 28)) == 0)
        return false;

    return is_cpu_gen_4();

#endif

    return false;
}

bool is_cpu_gen_4(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel
    // Intel 4th gen (Haswell)
    // https://www.intel.com/content/dam/develop/external/us/en/documents/how-to-detect-new-instruction-support-in-the-4th-generation-intel-core-processor-family.pdf

    // Check level of CPUID support
    if (! has_cpuid_level(0, 7))
        return false;
    if (! has_cpuid_level(0x80000000, 0x80000001))
        return false;

    // Check features

    // EAX 1 ECX 0
    if (! get_cpu_features(1, 0))
        return false;

    // FMA3
    if ((cpu.ecx & (1 << 12)) == 0)
        return false;

    // MOVBE
    if ((cpu.ecx & (1 << 22)) == 0)
        return false;

    // OSXSAVE
    if ((cpu.ecx & (1 << 27)) == 0)
        return false;

    // EAX 7 ECX 0
    if (! get_cpu_features(7, 0))
        return false;

    // BMI
    if ((cpu.ebx & (1 << 3)) == 0)
        return false;
    if ((cpu.ebx & (1 << 8)) == 0)
        return false;

    // EAX 0x80000001 ECX 0
    if (! get_cpu_features(0x80000001, 0))
        return false;

    // LZCNT
    if ((cpu.ecx & (1 << 5)) == 0)
        return false;
    
    return cpu_has_avx2();

#endif

    return false;
}

bool cpu_has_avx2(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    // Check level of CPUID support
    if (! has_cpuid_level(0, 7))
        return false;

    // Check features

    // EAX 7 ECX 0
    if (! get_cpu_features(7, 0))
        return false;

    // AVX2
    if ((cpu.ebx & (1 << 5)) == 0)
        return false;

    return cpu_has_avx();

#endif

    return false;
}

bool cpu_has_avx(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    // Check level of CPUID support
    if (! has_cpuid_level(0, 1))
        return false;

    // Check features

    // EAX 1 ECX 0
    if (! get_cpu_features(1, 0))
        return false;

    // AVX
    if ((cpu.ecx & (1 << 28)) == 0)
        return false;

    return cpu_has_sse4_2();

#endif

    return false;
}

bool cpu_has_sse4_2(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    // Check level of CPUID support
    if (! has_cpuid_level(0, 1))
        return false;

    // Check features

    // EAX 1 ECX 0
    if (! get_cpu_features(1, 0))
        return false;

    // SSE4.2
    if ((cpu.ecx & (1 << 20)) == 0)
        return false;

    // SSE4.1
    if ((cpu.ecx & (1 << 19)) == 0)
        return false;

    // POPCNT
    if ((cpu.ecx & (1 << 23)) == 0)
        return false;

    // AESNI
    if ((cpu.ecx & (1 << 25)) == 0)
        return false;

    // PCLMULQDQ
    if ((cpu.ecx & (1 << 1)) == 0)
        return false;

    return cpu_has_sse3();

#endif

    return false;
}

bool cpu_has_sse3(void) {
#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    // Check level of CPUID support
    if (! has_cpuid_level(0, 1))
        return false;

    // Check features

    // EAX 1 ECX 0
    if (! get_cpu_features(1, 0))
        return false;

    // SSSE3
    if ((cpu.ecx & (1 << 9)) == 0)
        return false;

    // SSE3
    if ((cpu.ecx & (1 << 0)) == 0)
        return false;

    // SSE2
    if ((cpu.edx & (1 << 26)) == 0)
        return false;

    // SSE
    if ((cpu.edx & (1 << 25)) == 0)
        return false;

    // MMX
    if ((cpu.edx & (1 << 23)) == 0)
        return false;

    return true;

#endif

    return false;
}



// -------------------------------------------------------------------------
// Identify the CPU

bool get_cpu_vendor(char *buffer, size_t len) {
    // Verify buffer
    if (buffer == NULL || len == 0)
        return false;

    buffer[0] = 0;

#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    // EAX 0 ECX 0
    if (! get_cpu_features(0, 0))
        return false;

    char vendor[16];

    *((uint32_t*)&vendor[0]) = cpu.ebx;
    *((uint32_t*)&vendor[4]) = cpu.edx;
    *((uint32_t*)&vendor[8]) = cpu.ecx;
    vendor[12] = 0;
    
    strncpy(buffer, vendor, len);
    strterm(buffer, len);

    return true;
    
#endif

    return false;
}

bool get_cpu_brand(char *buffer, size_t len) {
    // Verify buffer
    if (buffer == NULL || len == 0)
        return false;

    buffer[0] = 0;

    char brand[64];

#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

    // Check level of CPUID support
    if (! has_cpuid_level(0x80000000, 0x80000004))
        return false;

    // EAX 0x80000002 ECX 0
    if (! get_cpu_features(0x80000002, 0))
        return false;

    *((uint32_t*)&brand[0])  = cpu.eax;
    *((uint32_t*)&brand[4])  = cpu.ebx;
    *((uint32_t*)&brand[8])  = cpu.ecx;
    *((uint32_t*)&brand[12]) = cpu.edx;

    if (! get_cpu_features(0x80000003, 0))
        return false;

    *((uint32_t*)&brand[16]) = cpu.eax;
    *((uint32_t*)&brand[20]) = cpu.ebx;
    *((uint32_t*)&brand[24]) = cpu.ecx;
    *((uint32_t*)&brand[28]) = cpu.edx;

    if (! get_cpu_features(0x80000004, 0))
        return false;

    *((uint32_t*)&brand[32]) = cpu.eax;
    *((uint32_t*)&brand[36]) = cpu.ebx;
    *((uint32_t*)&brand[40]) = cpu.ecx;
    *((uint32_t*)&brand[44]) = cpu.edx;
    brand[48] = 0;
    
    strncpy(buffer, brand, len);
    strterm(buffer, len);

    return true;

#elif defined(__aarch64__) || defined(__arm__) // 64- or 32-bit ARM
    
    char    buf[64];
    int64_t ret;
    size_t  size;

    // Let's try to get Mac info
    size = sizeof(buf);
    if (sysctlbyname("machdep.cpu.brand_string", buf, &size, NULL, 0) == 0) {
        bufterm(buf);
        
        ret  = 0;
        size = sizeof(ret);
        if (sysctlbyname("hw.ncpu", &ret, &size, NULL, 0) == 0) {
            snprintf(brand, sizeof(brand), "%s %lld-Core", buf, ret);
            bufterm(brand);

            strncpy(buffer, brand, len);
            strterm(buffer, len);
            
            return true;
        }
    }

#endif

    return false;
}

bool get_cpu_simd(char *buffer, size_t len) {
    // Verify buffer
    if (buffer == NULL || len == 0)
        return false;

    buffer[0] = 0;

    char simd[1024];

#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel
    simd[0] = 0;
    
    if (cpu_has_sse3()) {
        strcat(simd, "SSE3 ");
    }
    if (cpu_has_sse4_2()) {
        strcat(simd, "SSE4.2 ");
    }
    if (cpu_has_avx()) {
        strcat(simd, "AVX ");
    }
    if (cpu_has_avx2()) {
        strcat(simd, "AVX2 ");
    }
    if (is_cpu_gen_4()) {
        strcat(simd, "GEN4 ");
    }
    if (cpu_has_avx512_f_cd()) {
        strcat(simd, "AVX512-F-CD ");
    }
    if (cpu_has_avx512_er_pf()) {
        strcat(simd, "AVX512-ER-PF ");
    }
    if (cpu_has_avx512_vl_dq_bw()) {
        strcat(simd, "AVX512-VL-DQ-BW ");
    }
    if (cpu_has_avx512_ifma_vbmi()) {
        strcat(simd, "AVX512-IFMA-VBMI ");
    }
    bufterm(simd);
    
    strncpy(buffer, simd, len);
    strterm(buffer, len);

    return true;

#elif defined(__aarch64__) || defined(__arm__)  // ARM

    char    buf[32];
    int64_t ret;
    size_t  size;
    
    // Let's try to get Mac info
    if (sysctlbyname("machdep.cpu.brand_string", NULL, &size, NULL, 0) == 0) {
        ret  = 0;
        size = sizeof(ret);
        
        // If we have multiple performance levels show core counts
        if (sysctlbyname("hw.nperflevels", &ret, &size, NULL, 0) == 0) {
            simd[0] = 0;

            for (int i = 0; i < (int) ret; ++i) {
                char name[64];
                
                snprintf(name, sizeof(name), "hw.perflevel%d.name", i);
                bufterm(name);
                
                size = sizeof(buf);
                if (sysctlbyname(name, buf, &size, NULL, 0) == 0) {
                    bufterm(buf);

                    strcat(simd, buf);
                    strcat(simd, " ");
                }
                
                snprintf(name, sizeof(name), "hw.perflevel%d.physicalcpu", i);
                bufterm(name);

                ret  = 0;
                size = sizeof(ret);
                if (sysctlbyname(name, &ret, &size, NULL, 0) == 0) {
                    snprintf(buf, sizeof(buf), "%lld", ret);
                    bufterm(buf);

                    strcat(simd, buf);
                    strcat(simd, " ");
                }
            }
        }
        
        strncpy(buffer, simd, len);
        strterm(buffer, len);
    }

    return true;

#endif

    return false;
}
