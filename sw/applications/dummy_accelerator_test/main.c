#include <stdio.h>
#include <stdlib.h>

#define DUMMY_ITERATIVE(dest, source, latency) \
    asm volatile (".insn i 119, 0, %0, %1,"#latency \
    : "=r" (dest)\
    : "r" (source));

#define DUMMY_PIPELINE(dest, source, latency) \
    asm volatile (".insn i 91, 0, %0, %1,"#latency \
    : "=r" (dest)\
    : "r" (source));

int main(void)
{
    volatile register int dest = 0;
    register int source = 42;
    register int source2 = 2;
    dest = source + source2; //44
    source2 +=dest; //46
    source *= source2;  //1936
    //DUMMY_ITERATIVE(dest, source, 7);
    DUMMY_PIPELINE(dest, source, 5);
    DUMMY_PIPELINE(dest, source, 5);
    DUMMY_PIPELINE(dest, source, 5);
    //DUMMY(dest, source, 1);
    //asm volatile ("add %0, %1, %2" : "=r" (dest) : "r" (source), "r" (source2));
    dest = source + source2;
    dest = source *source2;
    return 0;
}

