// gcc mp.c --openmp -o mp 

#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <complex.h>
#include <math.h>

#define MAX_N 512

struct Matrix {
    int    size;
    double mat[MAX_N][MAX_N];
};

struct FreqMatrix {
    int    size;
    double complex mat[MAX_N][MAX_N];
};

void readMatrix(struct Matrix *m) {
    scanf("%d", &(m->size));
    for (int i = 0; i < m->size; i++)
        for (int j = 0; j < m->size; j++)
            scanf("%lf", &(m->mat[i][j]));
}

double complex dft(struct Matrix *mat, int k, int l) {
    double complex element = 0.0;
    int n;
    #pragma omp for schedule(static, 1)
    for (int m = 0; m < mat->size; m++) {
        for (n = 0; n < mat->size; n++) {
            double complex arg      = (k*m / (double) mat->size) + (l*n / (double) mat->size);
            double complex exponent = cexp(-2.0I * M_PI * arg);
            element += mat->mat[m][n] * exponent;
        }
    }
    return element / (double) (mat->size*mat->size);
}

int main(void) {
    struct Matrix     source;
    struct FreqMatrix freq_domain;
    readMatrix(&source);
    int num_procs =  omp_get_max_threads();
    int num_threads = num_procs * 1;
    freq_domain.size = source.size;
    int l;
    #pragma omp parallel num_threads(num_threads)
    for (int k = 0; k < source.size; k++) {
        #pragma omp for schedule(static, 1)
        for (l = 0; l < source.size; l++) {
            freq_domain.mat[k][l] = dft(&source, k, l);
        }
    } 

    double complex sum = 0.0;
    for (int k = 0; k < source.size; k++) {
        for (int l = 0; l < source.size; l++) {
            double complex el = freq_domain.mat[k][l];
            printf("(%lf, %lf) ", creal(el), cimag(el));
            sum += el;
        }
        printf("\n");
    }
    sum /= source.size;
    printf("Average : (%lf, %lf)", creal(sum), cimag(sum));
 
    return 0;
}


