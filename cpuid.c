// cpuid.c

#include <stdio.h>

#include "cpuinfo.h"

int main (void) {
    char buffer[256];

    if (get_cpu_vendor(buffer, sizeof(buffer))) {
        printf("%s ", buffer);
    }
    if (get_cpu_brand(buffer, sizeof(buffer))) {
        printf("%s\n", buffer);
    }
    if (get_cpu_features(buffer, sizeof(buffer))) {
        printf("%s\n", buffer);
    }

    return 0;
}
