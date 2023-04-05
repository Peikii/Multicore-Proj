#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(int argc, char *argv[]) {
    int N = atoi(argv[1]); // number of threads
    int num = atoi(argv[2]); // number of characters in file
    char *filename = argv[3]; // name of file
    FILE *fp; // file pointer
    char *buffer; // load the whole file in an array of characters
    int count[4]={0}; // the final combined array of 4 arrays to store frequency of each character for each thread
    int max_count = 0; // maximum frequency of the character
    char max_char; // character with maximum frequency

    // ============================================================================================================
    // Pure sequential version
    if (N == 0){
        int count_pure[4] = {0}; // array to count characters

        buffer = (char *) malloc(num * sizeof(char)); // allocate memory for buffer

        fp = fopen(filename, "r"); // open file for reading
        if (fp == NULL) {
            printf("Error opening file!!!\n");
            free(buffer);
            return 1;
        }

        fread(buffer, sizeof(char), num, fp); // read the file into the buffer
        fclose(fp); // close the file
        

        for (int i = 0; i < num; i++) { // loop throughout the characters in buffer

            char c = buffer[i];  // read a character from file

            switch (c) { // increment corresponding occurency
                case 'a':
                    count_pure[0]++;
                    break;
                case 'b':
                    count_pure[1]++;
                    break;
                case 'c':
                    count_pure[2]++;
                    break;
                case 'd':
                    count_pure[3]++;
                    break;
                default:
                    break;
            }
        }

        for (int i = 0; i < 4; i++) {
            if (count_pure[i] > max_count) {
                max_count = count_pure[i];
                max_char = 'a' + i; // converting index 'i' into char value
            }
        }
        printf("%c occurred the most %d times of a total of %d characters.\n", max_char, max_count, num);

        free(buffer); // free memory allocated for buffer
        return 0;
    }

    // ============================================================================================================
    // OpenMP parallel version
    else{
        buffer = (char *) malloc(num * sizeof(char)); // allocate memory for buffer

        fp = fopen(filename, "r"); // open file for reading
        if (fp == NULL) {
            printf("Error opening file!!!\n");
            free(buffer);
            return 1;
        }

        fread(buffer, sizeof(char), num, fp); // read the file into the buffer
        fclose(fp); // close the file

        // Start parallel region with N threads
        #pragma omp parallel num_threads(N)
        {
            int id = omp_get_thread_num(); // get thread ID
            int start = id * (num / N); // calculate start index for this thread
            int end = (id + 1) * (num / N); // calculate end index for this thread
            int count_local[4] = {0}; // Private count array for each thread

            if (id == N - 1) { // handle case when N is not divisible by num
                // Add the rest characters to the last thread
                end += num % N;
            }
            
            for (int i = start; i < end; i++) { // loop through characters in buffer for this thread

                char c = buffer[i];  // read a character from file
                // printf("Thread %d reads %c\n", omp_get_thread_num(), c); // print which thread reads which character (Test)


                switch (c) { // determine which entry of array to increment based on character read from buffer
                    case 'a':
                        count_local[0]++;
                        break;
                    case 'b':
                        count_local[1]++;
                        break;
                    case 'c':
                        count_local[2]++;
                        break;
                    case 'd':
                        count_local[3]++;
                        break;
                    default:
                        break;
                }
            }

            // Combine arrays for each thread in to one
            #pragma omp critical
            {
                for (int i = 0; i < 4; i++) {
                    count[i] += count_local[i];
                }
            }
        }

        // loop through entries in array to find maximum frequency and corresponding
        for (int i = 0; i < 4; i++) {
            if (count[i] > max_count) {
                max_count = count[i];
                max_char = 'a' + i; // converting index 'i' into char value
            }
        }

        printf("%c occurred the most %d times of a total of %d characters.\n", max_char, max_count, num);

        free(buffer); // free memory allocated for buffer
        return 0;
    }

}
