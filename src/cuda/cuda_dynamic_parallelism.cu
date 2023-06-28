#include <cuda/std/complex>
#include <cuda/functional>
#include <complex>
#include <iostream>
#include <vector>
#include <string>
#include <assert.h>
#include <cuComplex.h>

//////////////////////////////////////////////////////////////
// CUDA ERROR HANDLING
//////////////////////////////////////////////////////////////
void checkAsync(cudaError_t err, std::string position = "") {
    if (err != cudaSuccess) {
        std::cerr << "Cuda Runtime Error at " << position << std::endl;
        std::cerr << cudaGetErrorString(err) << std::endl;
        std::exit(EXIT_FAILURE);
    }
}

void checkSync(std::string position = "") {
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        std::cerr << "Cuda Runtime Error at " << position << std::endl;
        std::cerr << cudaGetErrorString(err) << std::endl;
        std::exit(EXIT_FAILURE);
    }
}

//////////////////////////////////////////////////////////////
// NECESSARY FUNCTIONS FOR DFT
//////////////////////////////////////////////////////////////
__device__ constexpr cuda::std::complex<double> operator""_i(long double d) {
    return cuda::std::complex<double>{0.0, static_cast<double>(d)};
}

__device__ constexpr cuda::std::complex<double> pi() {
    return atan(1.0) * 4;
}

void printMatrix(double* matrix, int* matSize) {
    int size = *matSize;
    std::cout << size << std::endl;

    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            std::cout << matrix[i * size + j] << " ";
        }
        std::cout << std::endl;
    }
}

void printResult(cuda::std::complex<double>* result, int size) {
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            // std::cout << "(" << result[i * size + j].real() << ", " << result[i * size + j].imag() << ")" << " ";
            printf("(%.6lf, %.6lf) ", result[i * size + j].real(), result[i * size + j].imag());
        }
        std::cout << std::endl;
    }
}

__device__ cuda::std::complex<double> dftElement(double* source, int size, int k, int l) {
    cuda::std::complex<double> element(0.0, 0.0);

    for (int m = 0; m < size; m++) {
        for (int n = 0; n < size; n++) {
            cuda::std::complex<double> sample = (k * m / (double)size) + (l * n / (double)size);
            cuda::std::complex<double> exponent = exp(-2.0_i * pi() * sample);
            element += source[m * size + n] * exponent;
        }
    }

    return element / (cuda::std::complex<double>)(size * size);
}

//////////////////////////////////////////////////////////////
// KERNEL FUNCTION
//////////////////////////////////////////////////////////////
__global__ void device_hello_world() {
    printf("Hello world from x.%d y.%d z.%d!\n", threadIdx.x, threadIdx.y, threadIdx.z);
}

__global__ void dft_sub_kernel(double* source, int size, int gridRow, int gridCol, cuDoubleComplex* sum, cuda::std::complex<double>* result) {
    int row = gridRow * 32 + blockIdx.y * blockDim.y + threadIdx.y;
    int col = gridCol * 32 + blockIdx.x * blockDim.x + threadIdx.x;

    if ((row >= size) || (col >= size)) {
        return;
    }

    result[row * size + col] = dftElement(source, size, row, col);

    atomicAdd(&(sum->x), result[row * size + col].real());
    atomicAdd(&(sum->y), result[row * size + col].imag());
}

__global__ void dft_kernel(double* source, int size, cuDoubleComplex* sum, cuda::std::complex<double>* result) {
    dim3 threads_per_block(32, 32, 1);
    dim3 blocks_per_grid(1, 1, 1);

    cudaStream_t s;
    cudaStreamCreateWithFlags(&s, cudaStreamNonBlocking);
    dft_sub_kernel << <blocks_per_grid, threads_per_block, 0, s >> > (source, size, threadIdx.x, threadIdx.y, sum, result);
    cudaStreamDestroy(s);
}

//////////////////////////////////////////////////////////////
// MAIN FUNCTION. LET'S GO!!!
//////////////////////////////////////////////////////////////
int main(void) {
    int size;
    double* source_host;

    // Read Matrix
    std::cin >> size;
    source_host = (double*)malloc(size * size * sizeof(double));
    for (int i = 0; i < size * size; i++) {
        std::cin >> source_host[i];
    }

    // Print Matrix
    // printMatrix(source_host, &size);

    double* source_gpu;
    cuDoubleComplex sum_host = make_cuDoubleComplex(0.0, 0.0);
    cuDoubleComplex* sum_gpu;

    cuda::std::complex<double>* result_gpu;
    cuda::std::complex<double>* result_host = (cuda::std::complex<double>*)malloc(size * size * sizeof(cuda::std::complex<double>));

    checkAsync(cudaMalloc(&source_gpu, sizeof(double) * size * size), "Malloc source to GPU");
    checkAsync(cudaMemcpy(source_gpu, source_host, sizeof(double) * size * size, cudaMemcpyHostToDevice), "Memcpy source to GPU");

    checkAsync(cudaMalloc(&sum_gpu, sizeof(cuDoubleComplex)), "Malloc sum to GPU");
    checkAsync(cudaMemcpy(sum_gpu, &sum_host, sizeof(cuDoubleComplex), cudaMemcpyHostToDevice), "Memcpy sum to GPU");

    checkAsync(cudaMalloc(&result_gpu, sizeof(cuda::std::complex<double>) * size * size), "Malloc result to GPU");
    checkAsync(cudaMemcpy(result_gpu, result_host, sizeof(double) * size * size, cudaMemcpyHostToDevice), "Memcpy result to GPU");

    int block_count = std::ceil((double)(size) / (double)(32));
    dim3 threads_per_block(block_count, block_count, 1);
    dim3 blocks_per_grid(1, 1, 1);

    dft_kernel << <blocks_per_grid, threads_per_block >> > (source_gpu, size, sum_gpu, result_gpu);

    cudaDeviceSynchronize();

    checkAsync(cudaMemcpy(&sum_host, sum_gpu, sizeof(cuDoubleComplex), cudaMemcpyDeviceToHost), "Memcpy sum to HOST");
    checkAsync(cudaMemcpy(result_host, result_gpu, sizeof(cuda::std::complex<double>) * size * size, cudaMemcpyDeviceToHost), "Memcpy result to HOST");

    printResult(result_host, size);
    sum_host.x /= size;

    // std::cout << "Average : (" << sum_host.real() << "," << sum_host.imag() << ")" << std::endl;
    printf("Average: (%.6lf, %.6lf)\n", cuCreal(sum_host), cuCimag(sum_host));

    checkAsync(cudaFree(source_gpu), "Free source");
    checkAsync(cudaFree(result_gpu), "Free result");
    checkAsync(cudaFree(sum_gpu), "Free sum");

    delete[] source_host;
    delete[] result_host;
    return 0;
}