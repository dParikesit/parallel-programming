# parallel-programming
OpenMPI, OpenMP, and CUDA based parallelization for Discrete Fourier Transform (DFT)

> Based on my course project on parallelization

I forgot the exact number, but these are what I remembered based on my current laptop (Zephyrus G14 2021 with Ryzen 9 5900HS and RTX 3060 mobile)

For test case 256, serial is around 3.5min, OpenMPI and OpenMP is around 3-4x faster
For test case 512, serial is around 1 hour, CUDA is under 1 minute

Disclaimer: OpenMP is made by Marcellus Michael Herman Kahari