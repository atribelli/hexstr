// decstr.h

#ifndef decstr_h
#define decstr_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

    const char * u64ToDecStr (char *buffer, uint64_t value);
    const char * s64ToDecStr (char *buffer,  int64_t value);
    const char * u32ToDecStr (char *buffer, uint32_t value);
    const char * s32ToDecStr (char *buffer,  int32_t value);

#ifdef __cplusplus
}
#endif

#endif /* decstr_h */
