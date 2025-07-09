#define MAXCPU 2
#define MAXMEM 100

#define WZR 0
#define IP cpu[currentCPU].ip
#define SP cpu[currentCPU].sp
#define X29 cpu[currentCPU].x29
#define X30 cpu[currentCPU].x30
#define W0 cpu[currentCPU].w0
#define W1 cpu[currentCPU].w1
#define W8 cpu[currentCPU].w8
#define W9 cpu[currentCPU].w9
#define W10 cpu[currentCPU].w10

#define FLAGZ cpu[currentCPU].flag_z
#define FLAGN cpu[currentCPU].flag_n

typedef CPU {
    int ip;
    int sp;
    int x29, x30;
    int w0, w1, w8, w9, w10;

    bit flag_z;
    bit flag_n;
};

CPU cpu[MAXCPU];
int memory[MAXMEM / 4];

//Разные типы аргументов a, b: 
//rm = register, memory
//rr = register, register
//mr = memory, register
//cm = const, memory (то же самое как register, memory тк берется просто значение)

inline sub_rrc(a, b, c) { 
    atomic { a = b - c; }
}

inline subs_rrr(a, b, c) { 
    atomic { 
        a = b - c; 
        FLAGZ = a == 0;
        FLAGN = a < 0;
    }
}

inline add_rrc(a, b, c) { 
    atomic { a = b + c; }
}

inline mul_rrr(a, b, c) { 
    atomic { a = b * c; }
}

inline sdiv_rrr(a, b, c) { 
    atomic { a = b / c; }
}

inline stur_rm(a, b) { 
    atomic { memory[(b) / 4] = a; }
}

inline str_rm(a, b) { 
    atomic { memory[(b) / 4] = a; }
}

inline ldur_rm(a, b) { 
    atomic { a = memory[(b) / 4]; }
}

inline ldr_rm(a, b) { 
    atomic { a = memory[(b) / 4]; }
}

inline mov_rc(a, b) { 
    atomic { a = b; }
}


inline NEXT_INSTRUCTION() {
    atomic {
        IP++;
        printf("CPU %d go to instruction %d...\n", currentCPU, IP);
    }
}

proctype cpuProc(int currentCPU) {
    IP = 1;

    do
        //::(IP == 1) -> { sub_rrc(SP, SP, 48); NEXT_INSTRUCTION(); }
        //::(IP == 2) -> { stp_rrm(X29, X30, SP + 32); NEXT_INSTRUCTION(); }
        ::(IP == 1) -> { add_rrc(X29, SP, 32); IP = 4; }
        ::(IP == 4) -> { stur_rm(W0, X29 - 4); NEXT_INSTRUCTION(); }
        ::(IP == 5) -> { stur_rm(W1, X29 - 8); NEXT_INSTRUCTION(); }
        ::(IP == 6) -> { ldur_rm(W8, X29 - 4); NEXT_INSTRUCTION(); }
        ::(IP == 7) -> { stur_rm(W8, X29 - 12); NEXT_INSTRUCTION(); }
        ::(IP == 8) -> { IP = 9; } //b LBB1_1
        //LBB1_1
        ::(IP == 9) -> { ldur_rm(W8, X29 - 12); NEXT_INSTRUCTION(); }
        ::(IP == 10) -> { ldur_rm(W9, X29 - 8); NEXT_INSTRUCTION(); }
        ::(IP == 11) -> { subs_rrr(W8, W8, W9); NEXT_INSTRUCTION(); }
        ::(IP == 12) -> { atomic {if ::(FLAGZ == 0 && FLAGN == 0) -> IP = 52; :: else -> NEXT_INSTRUCTION(); fi } }//b.gt LBB1_12
        ::(IP == 13) -> { IP = 14; } //b LBB1_2
        //LBB1_2
        ::(IP == 14) -> { ldur_rm(W9, X29 - 12); NEXT_INSTRUCTION(); }
        ::(IP == 15) -> { mov_rc(W8, 2); NEXT_INSTRUCTION(); }
        ::(IP == 16) -> { sdiv_rrr(W9, W9, W8); NEXT_INSTRUCTION(); }
        ::(IP == 17) -> { str_rm(W9, SP + 16); NEXT_INSTRUCTION(); }
        ::(IP == 18) -> { mov_rc(W9, 1); NEXT_INSTRUCTION(); }
        ::(IP == 19) -> { str_rm(W9, SP + 12); NEXT_INSTRUCTION(); }
        ::(IP == 20) -> { str_rm(W8, SP + 8); NEXT_INSTRUCTION(); }
        ::(IP == 21) -> { IP = 22; } //b LBB1_3
        //LBB1_3
        ::(IP == 22) -> { ldr_rm(W8, SP + 8); NEXT_INSTRUCTION(); }
        ::(IP == 23) -> { ldr_rm(W9, SP + 16); NEXT_INSTRUCTION(); }
        ::(IP == 24) -> { subs_rrr(W8, W8, W9); NEXT_INSTRUCTION(); }
        ::(IP == 25) -> { atomic {if ::(FLAGZ == 0 && FLAGN == 0) -> IP = 41; :: else -> NEXT_INSTRUCTION(); fi } } //b.gt LBB1_8
        ::(IP == 26) -> { IP = 27; } //b LBB1_4
        //LBB1_4
        ::(IP == 27) -> { ldur_rm(W8, X29 - 12); NEXT_INSTRUCTION(); }
        ::(IP == 28) -> { ldr_rm(W10, SP + 8); NEXT_INSTRUCTION(); }
        ::(IP == 29) -> { sdiv_rrr(W9, W8, W10); NEXT_INSTRUCTION(); }
        ::(IP == 30) -> { mul_rrr(W9, W9, W10); NEXT_INSTRUCTION(); }
        ::(IP == 31) -> { subs_rrr(W8, W8, W9); NEXT_INSTRUCTION(); }
        ::(IP == 32) -> { atomic {if ::(W8 != 0) -> IP = 36; :: else -> NEXT_INSTRUCTION(); fi } } //cbnz	w8, LBB1_6
        ::(IP == 33) -> { IP = 34; } //b LBB1_5
        //LBB1_5
        ::(IP == 34) -> { str_rm(WZR, SP + 12); NEXT_INSTRUCTION(); }
        ::(IP == 35) -> { IP = 41; } //b LBB1_8
        //LBB1_6
        ::(IP == 36) -> { IP = 37; } //b LBB1_7
        //LBB1_7
        ::(IP == 37) -> { ldr_rm(W8, SP + 8); NEXT_INSTRUCTION(); }
        ::(IP == 38) -> { add_rrc(W8, W8, 1); NEXT_INSTRUCTION(); }
        ::(IP == 39) -> { str_rm(W8, SP + 8); NEXT_INSTRUCTION(); }
        ::(IP == 40) -> { IP = 22; } //b LBB1_3
        //LBB1_8
        ::(IP == 41) -> { ldr_rm(W8, SP + 12); NEXT_INSTRUCTION(); }
        ::(IP == 42) -> { atomic {if ::(W8 == 0) -> IP = 47; :: else -> NEXT_INSTRUCTION(); fi } } //cbz	w8, LBB1_10
        ::(IP == 43) -> { IP = 44; } //b LBB1_9
        //LBB1_9
        ::(IP == 44) -> { ldur_rm(W0, X29 - 12); NEXT_INSTRUCTION(); }
        ::(IP == 45) -> { printf("-------------------------------- Found prime: %d\n", W0); NEXT_INSTRUCTION(); } //bl process_prime
        ::(IP == 46) -> { IP = 47; } //b LBB1_10
        //LBB1_10
        ::(IP == 47) -> { IP = 48; } //b LBB1_11
        //LBB1_11
        ::(IP == 48) -> { ldur_rm(W8, X29 - 12); NEXT_INSTRUCTION(); }
        ::(IP == 49) -> { add_rrc(W8, W8, 1); NEXT_INSTRUCTION(); }
        ::(IP == 50) -> { stur_rm(W8, X29 - 12); NEXT_INSTRUCTION(); }
        ::(IP == 51) -> { IP = 9; } //b LBB1_1
        //LBB1_12
        ::(IP == 52) -> { printf("Task for CPU %d done!\n", currentCPU); break; }
        // ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	    // add	sp, sp, #48
	    // ret
	    // .cfi_endproc ; -- End function
    od
}

active proctype main() {

    //изначальное распределение состояния, когда на двух процессорах работают две параллельные задачи
    cpu[0].sp = 0;
    cpu[1].sp = MAXMEM / 2;

    //1 ищет числа от 1 до 10000
    cpu[0].w0 = 1;
    cpu[0].w1 = 10000;

    //2 ищет числа от 10001 до 20000
    cpu[1].w0 = 10001;
    cpu[1].w1 = 20000;

    run cpuProc(0);
    run cpuProc(1);

}
