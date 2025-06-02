// cpuinfo.c

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cpuinfo.h"

// Intel CPUID support

#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux

#include <cpuid.h>

#elif defined(_M_X64)                       // 64-bit Intel Windows

#include <intrin.h>

#endif

// macOS sysctlbyname() support

#if defined(__APPLE__)                      // macOS

#include <sys/sysctl.h>

#endif

#if defined(_M_ARM64)                       // Windows ARM

#include <windows.h>

#endif



// -------------------------------------------------------------------------
// Let's be paranoid about string termination

#define strterm(buf, len) (buf)[(len)       - 1] = 0;
#define bufterm(buf)      (buf)[sizeof(buf) - 1] = 0;



#if defined(__arm__) || defined(__aarch64__) // ARM 32- or 64-bit

// -------------------------------------------------------------------------
// Lookup table for ARM implementors and parts.
// Use -1 to indicate no entry. For example a -1 for the part field
// indicates an implementor name. -1's for both the imp and part fields
// indicate the end of the table.
// https://github.com/bp0/armids

static struct {
    int  imp;
    int  part;
    char *name;
} arminfo[] = {
    0x41,    -1, "ARM",                     // Implementor
    0x41, 0x810, "ARM810",                  // Parts ...
    0x41, 0x920, "ARM920",
    0x41, 0x922, "ARM922",
    0x41, 0x926, "ARM926",
    0x41, 0x940, "ARM940",
    0x41, 0x946, "ARM946",
    0x41, 0x966, "ARM966",
    0x41, 0xa20, "ARM1020",
    0x41, 0xa22, "ARM1022",
    0x41, 0xa26, "ARM1026",
    0x41, 0xb02, "ARM11 MPCore",
    0x41, 0xb36, "ARM1136",
    0x41, 0xb56, "ARM1156",
    0x41, 0xb76, "ARM1176",
    0x41, 0xc05, "Cortex-A5",
    0x41, 0xc07, "Cortex-A7",
    0x41, 0xc08, "Cortex-A8",
    0x41, 0xc09, "Cortex-A9",
    0x41, 0xc0d, "Cortex-A17",              // # Originally A12
    0x41, 0xc0f, "Cortex-A15",
    0x41, 0xc0e, "Cortex-A17",
    0x41, 0xc14, "Cortex-R4",
    0x41, 0xc15, "Cortex-R5",
    0x41, 0xc17, "Cortex-R7",
    0x41, 0xc18, "Cortex-R8",
    0x41, 0xc20, "Cortex-M0",
    0x41, 0xc21, "Cortex-M1",
    0x41, 0xc23, "Cortex-M3",
    0x41, 0xc24, "Cortex-M4",
    0x41, 0xc27, "Cortex-M7",
    0x41, 0xc60, "Cortex-M0+",
    0x41, 0xd01, "Cortex-A32",
    0x41, 0xd03, "Cortex-A53",
    0x41, 0xd04, "Cortex-A35",
    0x41, 0xd05, "Cortex-A55",
    0x41, 0xd07, "Cortex-A57",
    0x41, 0xd08, "Cortex-A72",
    0x41, 0xd09, "Cortex-A73",
    0x41, 0xd0a, "Cortex-A75",
    0x41, 0xd0b, "Cortex-A76",
    0x41, 0xd0c, "Neoverse-N1",
    0x41, 0xd0d, "Cortex-A77",
    0x41, 0xd13, "Cortex-R52",
    0x41, 0xd20, "Cortex-M23",
    0x41, 0xd21, "Cortex-M33",
    0x41, 0xd4a, "Neoverse-E1",
    0x42, -1,    "Broadcom",
    0x42, 0x00f, "Brahma B15",
    0x42, 0x100, "Brahma B53",
    0x42, 0x516, "ThunderX2",
    0x43, -1,    "Cavium",
    0x43, 0x0a0, "ThunderX",
    0x43, 0x0a1, "ThunderX 88XX",
    0x43, 0x0a2, "ThunderX 81XX",
    0x43, 0x0a3, "ThunderX 83XX",
    0x43, 0x0af, "ThunderX2 99xx",
    0x44, -1,    "DEC",
    0x44, 0xa10, "SA110",
    0x44, 0xa11, "SA1100",
    0x4e, -1,    "nVidia",
    0x4e, 0x000, "Denver",
    0x4e, 0x003, "Denver 2",
    0x50, -1,    "APM",
    0x50, 0x000, "X-Gene",
    0x51, -1,    "Qualcomm",
    0x4e, 0x00f, "Scorpion",
    0x4e, 0x02d, "Scorpion",
    0x4e, 0x04d, "Krait",
    0x4e, 0x06f, "Krait",
    0x4e, 0x201, "Kryo",
    0x4e, 0x205, "Kryo",
    0x4e, 0x211, "Kryo",
    0x4e, 0x800, "Falkor V1/Kryo",
    0x4e, 0x801, "Kryo V2",
    0x4e, 0x802, "Kryo 3xx gold",
    0x4e, 0x803, "Kryo 3xx silver",
    0x4e, 0x805, "Kryo 5xx silver",
    0x4e, 0xc00, "Falkor",
    0x4e, 0xc01, "Saphira",
    0x53, -1,    "Samsung",
    0x53, 0x001, "exynos-m1",
    0x54, -1,    "Texas Instruments",
    0x56, -1,    "Marvell",
    0x56, 0x131, "Feroceon 88FR131",
    0x56, 0x581, "PJ4/PJ4b",
    0x56, 0x584, "PJ4B-MP",
    0x66, -1,    "Faraday",
    0x66, 0x526, "FA526",
    0x66, 0x626, "FA626",
    0x69, -1,    "Intel",
    0x69, 0x200, "i80200",
    0x69, 0x210, "PXA250A",
    0x69, 0x212, "PXA210A",
    0x69, 0x242, "i80321-400",
    0x69, 0x243, "i80321-600",
    0x69, 0x290, "PXA250B/PXA26x",
    0x69, 0x292, "PXA210B",
    0x69, 0x2c2, "i80321-400-B0",
    0x69, 0x2c3, "i80321-600-B0",
    0x69, 0x2d0, "PXA250C/PXA255/PXA26x",
    0x69, 0x2d2, "PXA210C",
    0x69, 0x2e3, "i80219",
    0x69, 0x411, "PXA27x",
    0x69, 0x41c, "IPX425-533",
    0x69, 0x41d, "IPX425-400",
    0x69, 0x41f, "IPX425-266",
    0x69, 0x682, "PXA32x",
    0x69, 0x683, "PXA930/PXA935",
    0x69, 0x688, "PXA30x",
    0x69, 0x689, "PXA31x",
    0x69, 0xb11, "SA1110",
    0x69, 0xc12, "IPX1200",
    -1,   -1,    ""                         // Mark end of table
};

static int get_arm_imp_part_entry(int imp, int part) {
    int i = 0;

    // Loop until end of table
    while (arminfo[i].imp != -1 || arminfo[i].part != -1) {
        // Return if we have a match
        if (arminfo[i].imp == imp && arminfo[i].part == part) {
            return i;
        }

        ++i;
    }

    // Indicate no match
    return -1;
}

#endif



#if defined(__x86_64__) || defined(_M_X64)  // 64-bit Intel

// -------------------------------------------------------------------------
// Return values from the cpuid instruction.
// Create a union so that regardless of API we can always access
// individual members as cpu.eax, etc.

static union {
    struct {
        uint32_t eax, ebx, ecx, edx;
    };
    int32_t regs[4];
} cpu;



// -------------------------------------------------------------------------
// Make sure we have the proper level of CPU functionality

static bool has_cpuid_level(int value, int level) {
#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux
    
    if (! __get_cpuid(value, &cpu.eax, &cpu.ebx, &cpu.ecx, &cpu.edx))
        return false;
    
#elif defined(_M_X64)                       // 64-bit Intel Windows
    
    __cpuid(cpu.regs, value);

#endif
    
    // Check level of CPUID support
    return cpu.eax >= level;
}



// -------------------------------------------------------------------------
// Get features from CPUID using the EAX ECX pair

static bool get_cpu_functionality(int eax_r, int ecx_r) {
#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux

    if (! __get_cpuid_count(eax_r, ecx_r,
                            &cpu.eax, &cpu.ebx, &cpu.ecx, &cpu.edx))
        return false;

#elif defined(_M_X64)                       // 64-bit Intel Windows

    __cpuidex(cpu.regs, eax_r, ecx_r);

#endif

    return true;
}

#endif



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
    if (! get_cpu_functionality(7, 0))
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
    if (! get_cpu_functionality(7, 0))
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
    if (! get_cpu_functionality(7, 0))
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
    if (! get_cpu_functionality(7, 0))
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
    if (! get_cpu_functionality(1, 0))
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
    if (! get_cpu_functionality(7, 0))
        return false;

    // BMI
    if ((cpu.ebx & (1 << 3)) == 0)
        return false;
    if ((cpu.ebx & (1 << 8)) == 0)
        return false;

    // EAX 0x80000001 ECX 0
    if (! get_cpu_functionality(0x80000001, 0))
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
    if (! get_cpu_functionality(7, 0))
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
    if (! get_cpu_functionality(1, 0))
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
    if (! get_cpu_functionality(1, 0))
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
    if (! get_cpu_functionality(1, 0))
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
// Get CPU info using macOS's sysctlbyname()

#if defined(__APPLE__)                      // macOS

static char *get_sysctlbyname_cores_info(void) {
    static char cores[2048] = "";
    int64_t     ret         = 0;
    size_t      size        = sizeof(ret);

    // Show the types of cores
    if (sysctlbyname("hw.nperflevels", &ret, &size, NULL, 0) == 0) {
        char name[64];
        char buf[32];

        int levels = (int) ret;
        for (int i = 0; i < levels; ++i) {
            snprintf(name, sizeof(name), "hw.perflevel%d.name", i);
            bufterm(name);
            
            size = sizeof(buf);
            if (sysctlbyname(name, buf, &size, NULL, 0) == 0) {
                bufterm(buf);

                strcat(cores, buf);
                strcat(cores, ":");
            }
            
            snprintf(name, sizeof(name), "hw.perflevel%d.physicalcpu", i);
            bufterm(name);

            ret  = 0;
            size = sizeof(ret);
            if (sysctlbyname(name, &ret, &size, NULL, 0) == 0) {
                snprintf(buf, sizeof(buf), "%lld", ret);
                bufterm(buf);

                strcat(cores, buf);
                strcat(cores, " ");
            }
        }
    }
    
    bufterm(cores);

    return(cores);
}

#endif



// -------------------------------------------------------------------------
// Get CPU info using Linux's /proc/cpuinfo

#if defined(__linux__)                      // Linux

static char *get_proc_cpuinfo_entry(FILE *fp, char *entry) {
    static char buf[2048];

    while (fgets(buf, sizeof(buf), fp) != NULL) {
        size_t size = strlen(entry);

        if (strncmp(buf, entry, size) == 0) {
            char *p = strchr(buf, ':');

            // Make sure we have a separator
            if (p != NULL && *(p + 1) != 0)
                // Move to the data
                p += 2;

                // Remove the newline
                p[strlen(p) - 1] = 0;

                // Return the string
                return p;
        }
    }

    // Indicate no match
    return NULL;
}

#endif



// -------------------------------------------------------------------------
// Identify the CPU vendor

#if defined(_M_X64) || defined(__x86_64__)  // 64-bit Intel

static bool get_cpu_vendor_intel(char *buffer, size_t len) {
    if (len < 13)
        return false;
    
    // EAX 0 ECX 0
    if (! get_cpu_functionality(0, 0))
        return false;

    *((uint32_t*)&buffer[0]) = cpu.ebx;
    *((uint32_t*)&buffer[4]) = cpu.edx;
    *((uint32_t*)&buffer[8]) = cpu.ecx;
    buffer[12] = 0;
    
    return true;
}

#endif



#if defined(_WIN64)                         // Windows

static bool get_cpu_vendor_windows(char *buffer, size_t len) {
#if defined(_M_X64)                         // 64-bit Intel
    
    return get_cpu_vendor_intel(buffer, len);

#elif defined(_M_ARM64)                     // 64-bit ARM
#endif
    
    return false;
}

#endif



#if defined(__APPLE__)                      // macOS

static bool get_cpu_vendor_macos(char *buffer, size_t len) {
    size_t size = len;
    if (sysctlbyname("machdep.cpu.vendor", buffer, &size, NULL, 0) == 0) {
        strterm(buffer, len);
        
        return true;
    }
    
    return false;
}

#endif



#if defined(__linux__)                      // Linux

static bool get_cpu_vendor_linux(char *buffer, size_t len) {
    bool  success = false;
    FILE *fp      = fopen("/proc/cpuinfo", "r");
    
    if (fp != NULL) {
        char *entry;

#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux

        entry = get_proc_cpuinfo_entry(fp, "vendor_id");
        if (entry != NULL) {
            snprintf(buffer, len, "%s", entry);
            strterm(buffer, len);
            
            success = true;
        }

#elif defined(__arm__) || defined(__aarch64__) // ARM 32- or 64-bit

        entry = get_proc_cpuinfo_entry(fp, "CPU implementer");
        if (entry != NULL) {
            int imp = strtol(entry, NULL, 16);
            
            imp = get_arm_imp_part_entry(imp, -1);
            if (imp > -1) {
                snprintf(buffer, len, "%s", arminfo[imp].name);
                strterm(buffer, len);
                
                success = true;
            }
        }

#endif

        fclose(fp);
    }
    
    return success;
}

#endif



bool get_cpu_vendor(char *buffer, size_t len) {
    // Verify buffer
    if (buffer == NULL || len == 0)
        return false;

    buffer[0] = 0;
    
#if defined(_WIN64)                         // Windows
    
    return get_cpu_vendor_windows(buffer, len);
    
#elif defined(__APPLE__)                    // macOS
    
    return get_cpu_vendor_macos(buffer, len);
    
#elif defined(__linux__)                    // Linux
    
    return get_cpu_vendor_linux(buffer, len);
    
#endif

    return false;
}



// -------------------------------------------------------------------------
// Identify the CPU part

static uint32_t get_cpu_family(uint32_t fam, uint32_t exfam) {
    if (fam == 15)
        fam += exfam;
    
    return fam;
}

static uint32_t get_cpu_model(uint32_t mod, uint32_t exmod, uint32_t fam) {
    if (fam == 6 || fam == 15)
        mod += exmod << 4;

    return mod;
}

#if defined(_M_X64) || defined(__x86_64__)  // 64-bit Intel

static bool get_cpu_part_intel(char *buffer, size_t len) {
    if (len < 32)
        return false;
    
    // Check level of CPUID support
    if (! has_cpuid_level(0, 1))
        return false;

    // Check features

    // EAX 1 ECX 0
    if (! get_cpu_functionality(1, 0))
        return false;

    int fam   = (cpu.eax >>  8) & 0x0f;
    int exfam = (cpu.eax >> 20) & 0xff;
    int mod   = (cpu.eax >>  4) & 0x0f;
    int exmod = (cpu.eax >> 16) & 0x0f;
    
    snprintf(buffer, len, "Family %d Model %d",
                          get_cpu_family (fam, exfam),
                          get_cpu_model  (mod, exmod, fam));
    strterm(buffer, len);
    
    return true;
}

#endif



#if defined(_WIN64)                         // Windows

static bool get_cpu_part_windows(char *buffer, size_t len) {
#if defined(_M_X64)                         // 64-bit Intel
    
    return get_cpu_part_intel(buffer, len);

#elif defined(_M_ARM64)                     // 64-bit ARM

    SYSTEM_INFO info;

    GetNativeSystemInfo(&info);
    if (info.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_ARM64) {
        char arch[16] = "";
        
        if (IsProcessorFeaturePresent(PF_ARM_V8_INSTRUCTIONS_AVAILABLE)) {
            strcpy(arch, "v8 ");
        }
        
        snprintf(buffer, len, "ARM %s%d-cores",
                              arch, info.dwNumberOfProcessors);
        strterm(buffer, len);

        return true;
    }

#endif
    
    return false;
}

#endif



#if defined(__APPLE__)                      // macOS

static bool get_cpu_part_macos(char *buffer, size_t len) {

#if defined(__x86_64__)                     // 64-bit Intel

    int64_t family = 0,
            model  = 0,
            cores  = 0;

    size_t size = sizeof(family);
    if (sysctlbyname("machdep.cpu.family",     &family, &size, NULL, 0) != 0)
        return false;

    size = sizeof(model);
    if (sysctlbyname("machdep.cpu.model",      &model,  &size, NULL, 0) != 0)
        return false;

    size = sizeof(cores);
    if (sysctlbyname("machdep.cpu.core_count", &cores,  &size, NULL, 0) != 0)
        return false;
    
    snprintf(buffer, len, "Family %lld Model %lld %lld-Core",
                          family, model, cores);
    strterm(buffer, len);

#elif defined(__aarch64__)                  // 64-bit ARM

    int64_t cores  = 0;

    size_t size = sizeof(cores);
    if (sysctlbyname("machdep.cpu.core_count", &cores,  &size, NULL, 0) != 0)
        return false;
    
    snprintf(buffer, len, "%lld-Core", cores);
    strterm(buffer, len);

#endif
    
    return true;
}

#endif



#if defined(__linux__)                      // Linux

static bool get_cpu_part_linux(char *buffer, size_t len) {
    bool  success = false;
    FILE *fp      = fopen("/proc/cpuinfo", "r");
    
    if (fp != NULL) {
        char *entry;

#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux

        long family = -1,
             model  = -1,
             cores  = -1;
        
        entry = get_proc_cpuinfo_entry(fp, "cpu family");
        if (entry != NULL) {
            family = strtol(entry, NULL, 10);
        }

        entry = get_proc_cpuinfo_entry(fp, "model");
        if (entry != NULL) {
            model = strtol(entry, NULL, 10);
        }

        entry = get_proc_cpuinfo_entry(fp, "cpu cores");
        if (entry != NULL) {
            cores = strtol(entry, NULL, 10);
        }
        
        if (family > 0 && model > 0 && cores > 0) {
            snprintf(buffer, len, "Family %ld Model %ld %ld-Core",
                                  family, model, cores);
            strterm(buffer, len);

            success = true;
        }

#elif defined(__arm__) || defined(__aarch64__) // ARM 32- or 64-bit
        
        long arch  = -1,
             imp   = -1,
             part  = -1,
             cores = -1;

        entry = get_proc_cpuinfo_entry(fp, "CPU architecture");
        if (entry != NULL) {
            arch = strtol(entry, NULL, 10);
        }

        entry = get_proc_cpuinfo_entry(fp, "CPU implementer");
        if (entry != NULL) {
            imp = strtol(entry, NULL, 16);
            
            entry = get_proc_cpuinfo_entry(fp, "CPU part");
            if (entry != NULL) {
                part = strtol(entry, NULL, 16);
                part = get_arm_imp_part_entry(imp, part);
            }
        }
        
        // There is no explicit count field, so count off processors
        do {
            entry = get_proc_cpuinfo_entry(fp, "processor");
            if (entry != NULL) {
                cores = strtol(entry, NULL, 10);
            }
            else {
                break;
            }
        }
        while (true);

        if (arch > 0 && part > 0 && cores > 0) {
            snprintf(buffer, len, "v%ld %s %ld-Core",
                                  arch, arminfo[part].name, cores + 1);
            strterm(buffer, len);
            
            success = true;
        };

#endif

        fclose(fp);
    }
    
    return success;
}

#endif



bool get_cpu_part(char *buffer, size_t len) {
    // Verify buffer
    if (buffer == NULL || len == 0)
        return false;
    
    buffer[0] = 0;

#if defined(_WIN64)                         // Windows
    
    return get_cpu_part_windows(buffer, len);
    
#elif defined(__APPLE__)                    // macOS
    
    return get_cpu_part_macos(buffer, len);
    
#elif defined(__linux__)                    // Linux
    
    return get_cpu_part_linux(buffer, len);
    
#endif

    return false;
}



// -------------------------------------------------------------------------
// Identify the CPU brand

#if defined(_M_X64) || defined(__x86_64__)  // 64-bit Intel

static bool get_cpu_brand_intel(char *buffer, size_t len) {
    if (len < 49)
        return false;
    
    // Check level of CPUID support
    if (! has_cpuid_level(0x80000000, 0x80000004))
        return false;

    // EAX 0x80000002 ECX 0
    if (! get_cpu_functionality(0x80000002, 0))
        return false;

    *((uint32_t*)&buffer[0])  = cpu.eax;
    *((uint32_t*)&buffer[4])  = cpu.ebx;
    *((uint32_t*)&buffer[8])  = cpu.ecx;
    *((uint32_t*)&buffer[12]) = cpu.edx;

    if (! get_cpu_functionality(0x80000003, 0))
        return false;

    *((uint32_t*)&buffer[16]) = cpu.eax;
    *((uint32_t*)&buffer[20]) = cpu.ebx;
    *((uint32_t*)&buffer[24]) = cpu.ecx;
    *((uint32_t*)&buffer[28]) = cpu.edx;

    if (! get_cpu_functionality(0x80000004, 0))
        return false;

    *((uint32_t*)&buffer[32]) = cpu.eax;
    *((uint32_t*)&buffer[36]) = cpu.ebx;
    *((uint32_t*)&buffer[40]) = cpu.ecx;
    *((uint32_t*)&buffer[44]) = cpu.edx;
    buffer[48] = 0;
    
    return true;
}

#endif



#if defined(_WIN64)                         // Windows

static bool get_cpu_brand_windows(char *buffer, size_t len) {
#if defined(_M_X64)                         // 64-bit Intel
    
    return get_cpu_brand_intel(buffer, len);
    
#elif defined(_M_ARM64)                     // 64-bit ARM
#endif
    
    return false;
}

#endif



#if defined(__APPLE__)                      // macOS

static bool get_cpu_brand_macos(char *buffer, size_t len) {
    size_t size = len;
    if (sysctlbyname("machdep.cpu.brand_string", buffer, &size, NULL, 0) == 0) {
        strterm(buffer, len);
        
        return true;
    }
    
    return false;
}

#endif



#if defined(__linux__)                      // Linux

static bool get_cpu_brand_linux(char *buffer, size_t len) {
    bool  success = false;
    FILE *fp      = fopen("/proc/cpuinfo", "r");
    
    if (fp != NULL) {
        char *entry;

#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux

        entry = get_proc_cpuinfo_entry(fp, "model name");

#elif defined(__arm__) || defined(__aarch64__) // ARM 32- or 64-bit

        entry = get_proc_cpuinfo_entry(fp, "Model");

#endif

        if (entry != NULL) {
            snprintf(buffer, len, "%s", entry);
            strterm(buffer, len);
            
            success = true;
        }

        fclose(fp);
    }
    
    return success;
}

#endif



bool get_cpu_brand(char *buffer, size_t len) {
    // Verify buffer
    if (buffer == NULL || len == 0)
        return false;

    buffer[0] = 0;

#if defined(_WIN64)                         // Windows
    
    return get_cpu_brand_windows(buffer, len);
    
#elif defined(__APPLE__)                    // macOS
    
    return get_cpu_brand_macos(buffer, len);
    
#elif defined(__linux__)                    // Linux
    
    return get_cpu_brand_linux(buffer, len);
    
#endif

    return false;
}



// -------------------------------------------------------------------------
// Identify the CPU features

#if defined(_M_X64) || defined(__x86_64__)  // 64-bit Intel

static bool get_cpu_features_intel(char *buffer, size_t len) {
    char simd[1024] = "";

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
}

#endif



#if defined(_WIN64)                         // Windows

static bool get_cpu_features_windows(char *buffer, size_t len) {
#if defined(_M_X64)                         // 64-bit Intel
    
    return get_cpu_features_intel(buffer, len);

#elif defined(_M_ARM64)                     // 64-bit ARM

    char features[2048] = "";

    if (IsProcessorFeaturePresent(PF_ARM_FMAC_INSTRUCTIONS_AVAILABLE)) {
        strcat(features, "FMAC ");
    }

    if (IsProcessorFeaturePresent(PF_ARM_VFP_32_REGISTERS_AVAILABLE)) {
        strcat(features, "NEON ");
    }

    strncpy(buffer, features, len);
    strterm(buffer, len);

    return true;

#endif

    return false;
}

#endif



#if defined(__APPLE__)                      // macOS

static bool get_cpu_features_macos(char *buffer, size_t len) {

#if defined(__x86_64__)                     // 64-bit Intel
    
    size_t size = len;
    if (sysctlbyname("machdep.cpu.features", buffer, &size, NULL, 0) == 0) {
        strterm(buffer, len);
        
        return true;
    }

#elif defined(__aarch64__)                  // 64-bit ARM

    char    features[2048] = "";
    int64_t ret            = 0;

    size_t size = sizeof(ret);
    if (   sysctlbyname("hw.optional.neon", &ret, &size, NULL, 0) == 0
        && ret == 1) {
        strcat(features, "neon ");
    }

    if (   sysctlbyname("hw.optional.neon_hpfp", &ret, &size, NULL, 0) == 0
        && ret == 1) {
        strcat(features, "neon_hpfp ");
    }

    if (   sysctlbyname("hw.optional.arm.FEAT_DotProd", &ret, &size, NULL, 0) == 0
        && ret == 1) {
        strcat(features, "FEAT_DotProd ");
    }

    snprintf(buffer, len, "%s", features);
    strterm(buffer, len);
    
    return true;

#endif
    
    return false;
}

#endif



#if defined(__linux__)                      // Linux

static bool get_cpu_features_linux(char *buffer, size_t len) {
    bool  success = false;
    FILE *fp      = fopen("/proc/cpuinfo", "r");

    if (fp != NULL) {
        char *entry;

#if defined(__x86_64__)                     // 64-bit Intel macOS or Linux

        entry = get_proc_cpuinfo_entry(fp, "flags");

#elif defined(__arm__) || defined(__aarch64__) // ARM 32- or 64-bit

        entry = get_proc_cpuinfo_entry(fp, "Features");

#endif

        if (entry != NULL) {
            snprintf(buffer, len, "%s", entry);
            strterm(buffer, len);
            
            success = true;
        }

        fclose(fp);
    }
    
    return success;
}

#endif



bool get_cpu_features(char *buffer, size_t len) {
    // Verify buffer
    if (buffer == NULL || len == 0)
        return false;
    
    buffer[0] = 0;
    
#if defined(_WIN64)                         // Windows
    
    return get_cpu_features_windows(buffer, len);
    
#elif defined(__APPLE__)                    // macOS
    
    return get_cpu_features_macos(buffer, len);
    
#elif defined(__linux__)                    // Linux
    
    return get_cpu_features_linux(buffer, len);
    
#endif
    
    return false;
}
