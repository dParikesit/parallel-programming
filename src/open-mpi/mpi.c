#define _USE_MATH_DEFINES

#include <mpi.h>
#include <complex.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define MAX_N 512
#define NODE_COUNT 4

struct Matrix {
    int    size;
    double* mat;
};

void readMatrix(struct Matrix* m) {
    scanf("%d", &(m->size));
    m->mat = (double*)malloc((m->size * m->size) * sizeof(double));
    for (int i = 0; i < m->size * m->size; i++) {
        scanf("%lf", &(m->mat[i]));
    }
}

void printMatrix(struct Matrix m) {
    printf("Size: %d\n", m.size);
    for (int i = 0; i < m.size; i++) {
        for (int j = 0; j < m.size; j++) {
            printf("%.2lf ", m.mat[i * m.size + j]);
        }
        printf("\n");
    }
}

void printArr(double complex* m, int length, int rank) {
    printf("=====================\n");
    printf("Rank: %d\n", rank);
    for (int i = 0; i < length; i++) {
        printf("(%lf, %lf) ", creal(m[i]), cimag(m[i]));
    }
    printf("\n");
    printf("=====================\n");
}

double complex dft(struct Matrix* mat, int k, int l) {
    double complex element = 0.0;
    for (int m = 0; m < mat->size; m++) {
        for (int n = 0; n < mat->size; n++) {
            double complex arg = (k * m / (double)mat->size) + (l * n / (double)mat->size);
            double complex exponent = cexp(-2.0I * M_PI * arg);
            element += mat->mat[m * mat->size + n] * exponent;
        }
    }
    return element / (double)(mat->size * mat->size);
}

int main(void) {
    struct Matrix source;

    // Initialize MPI
    MPI_Init(NULL, NULL);

    // Get world size and rank
    int world_rank, world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    // Stdin matrix to process 0
    if (world_rank == 0) {
        readMatrix(&source);
    }

    // Broadcast source matrix size
    MPI_Bcast(&source.size, 1, MPI_INT, 0, MPI_COMM_WORLD);

    // Malloc source matrix from size on process 0
    if (world_rank != 0) {
        source.mat = (double*)malloc((source.size * source.size) * sizeof(double));
    }

    // Broadcast source matrix content
    MPI_Bcast(source.mat, source.size * source.size, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    // Divide operations
    int rowOp = source.size / NODE_COUNT;
    int startIdx = world_rank * rowOp;
    int stopIdx = (world_rank + 1) * rowOp;
    double complex localSum = 0.0;

    if (world_rank == 0) {
        for (int l = 0; l < source.size; l++) {
            double complex temp = dft(&source, 0, l);
            localSum += temp;
            printf("(%lf, %lf) ", creal(temp), cimag(temp));
        }
        for (int k = 1; k < stopIdx; k++) {
            for (int l = 0; l < source.size; l++) {
                localSum += dft(&source, k, l);
            }
        }
    } else {
        for (int k = startIdx; k < stopIdx; k++) {
            for (int l = 0; l < source.size; l++) {
                localSum += dft(&source, k, l);
            }
        }
    }

    double complex globalSum = 0.0;
    MPI_Reduce(&localSum, &globalSum, 1, MPI_DOUBLE_COMPLEX, MPI_SUM, 0, MPI_COMM_WORLD);

    if (world_rank == 0) {
        globalSum /= source.size;
        printf("Average : (%lf, %lf)", creal(globalSum), cimag(globalSum));
    }

    // I'm free
    free(source.mat);

    // Stop MPI
    MPI_Finalize();
    return 0;
}