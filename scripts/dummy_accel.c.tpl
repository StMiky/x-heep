#define DUMMY_ITERATIVE(dest, source, latency) \
    asm volatile (".insn i 119, 0, %0, %1,"#latency \
    : "=r" (dest)\
    : "r" (source));

#define DUMMY_PIPELINE(dest, source, latency) \
    asm volatile (".insn i 91, 0, %0, %1,"#latency \
    : "=r" (dest)\
    : "r" (source));

#define ADD(dest, source1, source2) \
    asm volatile ("add %0, %1, %2" \
    : "=r" (dest)\
    : "r" (source1),\
    "r" (source2));

#define XOR(dest, source1, source2) \
    asm volatile ("xor %0, %1, %2" \
    : "=r" (dest)\
    : "r" (source1),\
    "r" (source2));

#define SUB(dest, source1, source2) \
    asm volatile ("sub %0, %1, %2" \
    : "=r" (dest)\
    : "r" (source1),\
     "r" (source2));



void sampleRegs(long unsigned int *mcycle, long unsigned int *minstret) {
    asm volatile ("csrr %0, mcycle" : "=r" (*mcycle));
    asm volatile ("csrr %0, minstret" : "=r" (*minstret));
}

void sampleRegs_(long unsigned int *mcycle, long unsigned int *minstret) {
    asm volatile ("csrr %0, minstret" : "=r" (*minstret));
    asm volatile ("csrr %0, mcycle" : "=r" (*mcycle));
}

int random_array [] = {
    37, 84, 56, 71, 93, 12, 45, 63, 28, 9, 77, 21, 88, 54, 18, 97, 34, 62, 75, 43,
    15, 80, 68, 25, 90, 31, 7, 49, 86, 29, 53, 14, 78, 66, 10, 59, 99, 22, 35, 82,
    4, 58, 47, 65, 16, 89, 40, 3, 76, 51, 26, 92, 17, 60, 98, 32, 8, 50, 67, 13,
    74, 20, 83, 39, 6, 72, 30, 44, 85, 33, 19, 61, 91, 38, 57, 95, 27, 41, 64, 11,
    81, 1, 70, 48, 23, 69, 94, 42, 5, 52, 79, 24, 87, 36, 73, 55, 2, 96, 46, 100
};

long int __attribute__((noinline)) bookeeping()  {
	int acc = 0;

${block_b}

	return acc;
}


void enablePerfCounters(void) {
  // Enable perf counters
  asm volatile ("csrw mcountinhibit, %0" : : "r" (0x8));
}

int main(void) {
    enablePerfCounters();
    register long int dest, dest_dummy;
    register int source;
    register int source2;
    long unsigned int mcycle_start, mcycle_stop;
    long unsigned int minstret_start, minstret_stop;
    long int new_result;

    asm volatile ("csrr %0, mcycle" : "=r" (source));
    asm volatile ("csrr %0, mcycle" : "=r" (source2));
    sampleRegs_(&mcycle_start, &minstret_start);

    // BLOCK A
    // ------------------------------------------------
${block_a}
    
    // DUMMY ACCELERATOR
    // ------------------------------------------------
${block_dummy}

    sampleRegs(&mcycle_stop, &minstret_stop);
    printf("C %lu\n", mcycle_stop - mcycle_start);
    printf("I %lu\n", minstret_stop - minstret_start);

    return dest_dummy;

}