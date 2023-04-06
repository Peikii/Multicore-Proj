#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <omp.h>

// Function to generate prime numbers up to N
void genprimes(int N, int t) {
    int *primes = (int *) calloc(N, sizeof(int)); // allocate an array of size N and initialize it with 0
    if (primes == NULL) {
        printf("Memory allocation error");
        return;
    }
    int i, j, numprimes = 0;
    primes[numprimes++] = 2; // 2 is the first prime

    #pragma omp parallel for num_threads(t) private(j) schedule(dynamic)
    for (i = 3; i <= N; i += 2) {
        bool isprime = true;
        int limit = sqrt(i);
        for (j = 0; j < numprimes; j++) {
            if (primes[j] > limit) break; // optimization: stop checking when the next prime is greater than the square root of the number being tested
            if (i % primes[j] == 0) {
                isprime = false;
                break;
            }
        }
        if (isprime) {
            #pragma omp critical
            {
                primes[numprimes++] = i;
            }
        }
    }
    FILE *outfile;
    char filename[15];
    sprintf(filename, "%d.txt", N); // generate the output filename
    outfile = fopen(filename, "w");
    if (outfile == NULL) {
        printf("Error creating file %s", filename);
        return;
    }
    fprintf(outfile, "1 2\n"); // 2 is always the first prime
    for (i = 1; i < numprimes; i++) {
        fprintf(outfile, "%d %d\n", i+1, primes[i]); // write the primes to the output file
    }
    fclose(outfile);
    free(primes);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: ./genprime N t\n");
        return 0;
    }
    int N = atoi(argv[1]);
    int t = atoi(argv[2]);
    if (N < 2 || t <= 0 || t > 100) {
        printf("Invalid input\n");
        return 0;
    }
    double tstart = 0.0, tend=0.0, ttaken;
    tstart = omp_get_wtime(); // measure the start time
    genprimes(N, t);
    ttaken = omp_get_wtime() - tstart; // measure the total time
    printf(“Time take for the main part: %f\n”, ttaken);
    return 0;
}
