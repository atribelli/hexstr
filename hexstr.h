// hexstr.h

#ifndef hexstr_h
#define hexstr_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

    const char * u64ToHexStr (char *buffer, uint64_t value);
    const char * u32ToHexStr (char *buffer, uint32_t value);
    const char * u16ToHexStr (char *buffer, uint16_t value);
    const char *  u8ToHexStr (char *buffer, uint8_t  value);
    const char *  u4ToHexStr (char *buffer, uint8_t  value);

#ifdef __cplusplus
}
#endif

#endif /* hexstr_h */
