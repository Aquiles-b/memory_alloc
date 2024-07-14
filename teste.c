#include <stdio.h>
#include "memalloc.h"

extern void *original_brk;

int main() {
    setup_brk();
    printf("%p\n", original_brk);
    

    return 0;
}
