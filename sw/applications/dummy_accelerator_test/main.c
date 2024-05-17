#include <stdio.h>
#include <stdlib.h>

#define DUMMY(dest, source, latency) \
    asm volatile (".insn i 119, 0, %0, %1,"#latency \
    : "=r" (dest)\
    : "r" (source));

int main(void)
{
    register int dest = 0;
    register int source = 42;
    register int source2 = 2;
    //DUMMY(dest, source, 5);
    asm volatile ("add %0, %1, %2" : "=r" (dest) : "r" (source), "r" (source2));
    return 0;
}

