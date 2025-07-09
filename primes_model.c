#include <stdio.h>

void process_prime(int prime) {
    printf("%d\n", prime);
}

void primes(int a, int b) {

    for (int i = a; i <= b; i++) {
	int max = i / 2;
	int isPrime = 1;
	for (int d = 2; d <= max; d++) 
	    if (i % d == 0) {
		isPrime = 0;
		break;
	    }
	if (isPrime) process_prime(i);
    }
}


int main() {

    primes(2, 10000);
    primes(10000, 20000);


}