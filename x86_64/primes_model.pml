//mtype:current_proc = {primes, process_prime}

#define MAXCPU 2
#define MAXMEM 100

#define IP cpu[currentCPU].ip
#define EDI cpu[currentCPU].edi
#define ESI cpu[currentCPU].esi
#define RBP cpu[currentCPU].rbp
#define RSP cpu[currentCPU].rsp
#define EAX cpu[currentCPU].eax
#define EDX cpu[currentCPU].edx
#define FLAGZ cpu[currentCPU].flag_z
#define FLAGS cpu[currentCPU].flag_s


typedef CPU {
    int ip;
    int rsp;
    int rbp;
    int eax;
    int ebx;
    int edx;
    int ecx;
    int edi;
    int esi;
    bit flag_z;
    bit flag_s;
};


CPU cpu[MAXCPU];
int memory[MAXMEM / 4];

/*
если использовать память побайтово, то не эффективно: 
byte memory[MAXMEM];
inline movl_rm(a, b) { 
atomic {
memory[(b) & 0xff] = a & 0xff;
memory[(b >> 8) & 0xff] = (a >> 8) & 0xff;
memory[(b >> 16) & 0xff] = (a >> 16) & 0xff;
memory[(b >> 24) & 0xff] = (a >> 24) & 0xff; 
}
}
*/


//Разные типы аргументов a, b: 
//rm = register, memory
//rr = register, register
//mr = momory, register
//cm = const, memory (то же самое как register, memory тк берется просто значение)

inline movl_rm(a, b) { 
    atomic { memory[(b) / 4] = a; }
}

inline movl_rr(a, b) { 
    atomic { b = a; }
}

inline movl_mr(a, b) { 
    atomic { b = memory[(a) / 4]; }
}

inline movl_cm(a, b) { 
    atomic { memory[(b) / 4] = a; }
}

inline shrl(a, b) { 
    atomic { b = b << a; }
}

inline addl(a, b) {
    atomic { b = a + b; }
}

inline addl_cm(a, b) {
    atomic { memory[b / 4] = a + memory[b / 4]; }
}

inline sarl(a) {
    atomic { a = a >> 1; }
}

//Расширение eax в edx:eax (для деления)
inline cltd() {
    atomic { EDX = EAX; }
}

//Делим a (edx:eax) на b 
inline idivl(b) {
    atomic { EAX = EAX % memory[(b) / 4]; EDX = EDX / memory[(b) / 4];}
}

inline testl(a, b) {
    atomic {
        FLAGZ = ((a) & (b) == 0);
        FLAGS = ((a) & (b) < 0);
    }
}

inline cmpl_mr(a, b) {
    atomic {
        FLAGZ = (memory[(a) / 4] == b);
        FLAGS = (memory[(a) / 4]  < b);
    }
}

inline cmpl_rm(a, b) {
    atomic {
        FLAGZ = (a == memory[(b) / 4]);
        FLAGS = (a < memory[(b) / 4]);
    }
}

inline NEXT_INSTRUCTION() {
    atomic {
        printf("CPU %d go to instruction %d...\n", currentCPU, IP);
        IP++;
    }
}

proctype cpuProc(int currentCPU) {
    do
        //::(IP == 1) -> { pushq(cpu[currentCPU].rbp); IP++; }
        ::(IP == 1) -> {movl_rr(RSP, RBP); /*movq(rsp, rbp)*/; IP = 4; }
        //::(IP == 3) -> { subq(32, rsp); IP++; }
        ::(IP == 4) -> {movl_rm(EDI, -20 + RBP); NEXT_INSTRUCTION()}
        ::(IP == 5) -> {movl_rm(ESI, -24 + RBP); NEXT_INSTRUCTION()}
        ::(IP == 6) -> {movl_mr(-20 + RBP, EAX); NEXT_INSTRUCTION()}
        ::(IP == 7) -> {movl_rm(EAX, -4 + RBP); NEXT_INSTRUCTION()}
        ::(IP == 8) -> {IP = 36;}//jmp .L3
        //.L9:
        ::(IP == 9) -> {movl_mr(-4 + RBP, EAX); NEXT_INSTRUCTION()}
        ::(IP == 10) -> {movl_rr(EAX, EDX); NEXT_INSTRUCTION()};
        ::(IP == 11) -> {shrl(31, EDX); NEXT_INSTRUCTION()} 
        ::(IP == 12) -> {addl(EDX, EAX); NEXT_INSTRUCTION()}
        ::(IP == 13) -> {sarl(EAX); NEXT_INSTRUCTION()}
        ::(IP == 14) -> {movl_rm(EAX, -16 + RBP); NEXT_INSTRUCTION()}
        ::(IP == 15) -> {movl_cm(1, -8 + RBP); NEXT_INSTRUCTION()}
        ::(IP == 16) -> {movl_cm(2, -12 + RBP); NEXT_INSTRUCTION()};
        ::(IP == 17) -> {IP = 27;}//jmp .L4
        //.L7:
        ::(IP == 18) -> {movl_mr(-4 + RBP, EAX); NEXT_INSTRUCTION()}
        ::(IP == 19) -> {cltd(); NEXT_INSTRUCTION()}
        ::(IP == 20) -> {idivl(-12 + RBP); NEXT_INSTRUCTION()}
        ::(IP == 21) -> {movl_rr(EDX, EAX); NEXT_INSTRUCTION()}
        ::(IP == 22) -> {testl(EAX, EAX); NEXT_INSTRUCTION()}
        ::(IP == 23) -> {atomic {if ::(FLAGZ == 0) -> IP = 26; else -> NEXT_INSTRUCTION(); fi}};//jne .L5
        ::(IP == 24) -> {movl_cm(0, -8 + RBP); NEXT_INSTRUCTION()}
        ::(IP == 25) -> {IP = 30};//jmp .L6
        //.L5:
        ::(IP == 26) -> {addl_cm(1, -12 + RBP); NEXT_INSTRUCTION()}
        //.L4:
        ::(IP == 27) -> {movl_mr(-12 + RBP, EAX); NEXT_INSTRUCTION()}
        ::(IP == 28) -> {cmpl_mr(-16 + RBP, EAX); NEXT_INSTRUCTION()}
        ::(IP == 29) -> {atomic {if ::(FLAGZ == 0 || FLAGS == 1)  -> IP = 18; else -> NEXT_INSTRUCTION(); fi}}//jle .L7
        //.L6:
        ::(IP == 30) -> {cmpl_rm(0, -8 + RBP); IP++;}
        ::(IP == 31) -> {atomic {if ::(FLAGZ == 1)  -> IP = 35; else -> NEXT_INSTRUCTION() fi}} //je .L8
        ::(IP == 32) -> {movl_mr(-4 + RBP, EAX); NEXT_INSTRUCTION() };
        ::(IP == 33) -> {movl_rr(EAX, EDI); NEXT_INSTRUCTION()}
        ::(IP == 34) -> {printf("Found prime: %d", EDI); NEXT_INSTRUCTION()} //call process_prime
        //.L8:
        ::(IP == 35) -> {addl_cm(1, -4 + RBP); NEXT_INSTRUCTION()}
        //.L3:
        ::(IP == 36) -> {movl_mr(-4 + RBP, EAX); NEXT_INSTRUCTION()}
        ::(IP == 37) -> {cmpl_mr(-24 + RBP, EAX); NEXT_INSTRUCTION()}
        ::(IP == 38) -> {atomic {if ::(FLAGZ == 0)  -> IP = 9; else -> NEXT_INSTRUCTION() fi}} //jle .L9
        ::(IP == 39) -> printf("Task for CPU %d done!\n", currentCPU);
        //nop
        //nop
        //leave
        //.cfi_def_cfa 7, 8
        //ret
        //.cfi_endproc
    od
}


proctype sched() {
    do
        ::true -> printf("selecting something (cpu, task, ...)") 
    od
}

active proctype main() {

    //изначальное распределение состояния, когда на двух процессорах работают две параллельные задачи
    cpu[0].rsp = MAXMEM / 2;
    cpu[1].rsp = MAXMEM;

    //1 ищет числа от 1 до 10000
    cpu[0].edi = 1;
    cpu[0].esi = 10000;

    //2 ищет числа от 10001 до 20000
    cpu[1].edi = 10001;
    cpu[1].esi = 20000;

    run cpuProc(0);
    run cpuProc(1);

}

proctype interrupt_gen() {
    do
        ::true -> printf("selecting something") 
    od
}
