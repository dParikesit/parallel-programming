# CUDA

## Penjelasan Cara Kerja Paralelisasi Program

Pada tucil 3 ini, dilakukan paralelisasi algoritma 2D DFT dengan menggunakan CUDA. CUDA merupakan salah satu platform komputasi paralel dan model pemorograman yang dibuat oleh NVIDIA dan diimplementasikan menggunakan GPU. <br/>

Paralelisme mengunakan CUDA dilakukan dengan membagi data input menjadi bagian yang lebih kecil dan mendistribusikan bagian tersebut ke banyak processing core di GPU. Setiap processing core menjalankan instruksi yang sama pada beberapa bagian data secara bersamaan. Sehingga, pemrosesan jauh lebih cepat dibandingkan dengan komputasi berbasis CPU biasa.

## Alasan pemilihan skema pembagian data

Terdapat dua implementasi versi CUDA yang kelompok kami buat, yaitu yang menggunakan dynamic parallelism `cuda_cdp.cu` dan yang tidak `cuda.cu`. Skema yang kami pilih adalah yang tidak mengginakan synamic parallelism karena seluruh elemen matriks dihitung DFTnya sehingga tidak perlu fleksibilitas yang dimiliki dynamic parallelism.

!!! File yang digunakan adalah yang `cuda.cu`, bukan `cuda_cdp.cu`

## Cara Program Membagikan Data Antar-proses atau Antar-thread

Terminologi yang digunakan

- Host : CPU
- Device : GPU

Alur kerja dari program adalah sebagai berikut.

1. Buat variable `source_host` dan `source_gpu` yang berisi `matrix input`, `sum_host`, dan `sum_gpu` yang berisi hasil penjumlahan dft tiap elemen. Lalu, buat `result_host` dan `result_gpu` yang berisi matrix hasil dft.
2. Lakukan host input matrix melalui `stdin`, inisialisasi `sum_host` dengan `complex(0.0,0.0)`.
3. Lakukan `cudaMalloc` dan `cudaMemcpy` untuk variable `source_gpu`, `sum_gpu`, dan `result_gpu`.
4. Panggil `dft_kernel` dengan parameter `source_gpu`, `size`, `sum_gpu`, `result_gpu`. `dft_kernel` akan memanggil fungsi `dft_element` sesuai posisi thread.
5. Panggil `cudaDeviceSynchronize` agar host menunggu semua thread selesai.
6. Panggil `cudaMemcpy` untuk `sum_host` dan `result_host` agar hasil dft dikembalikan ke host.
7. Host melakukan print hasil

Beberapa hal yang kami pilih untuk diimplementasikan dengan pertimbangan sebagai berikut.

1. Representasi double complex
   C++ memiliki representasi double complex dalam bentuk `std::complex<double>`. Akan tetapi nvidia tidak bisa menggunakan tipe data ini dalam device code.
   Oleh karena itu digunakan `cuDoubleComplex` dan `cuda::std::complex<double>` (lebih baru). Utamanya digunakan `cuda::std::complex` kecuali pada bagian fungsi `dft_kernel` karena melakukan `AtomicAdd` pada `cuda::std::complex`.

2. Cuda Error Handling
   Terdapat 2 jenis error pada cuda, synchronous dan async. Synchronous error terjadi ketika host (cpu) mengetahui bahwa kernel yang sedang dijalankan illegal atau invalid. Async error terjadi ketika eksekusi kernel atau pada cuda runtime async API seperti `cudaMalloc` dan `cudaMemcpy`. Kedua error tersebut perlu penanganan yang berbeda, sehingga dibuat dua wrapper function untuk error handling yaitu `checkSync` dan `checkAsync`.

3. Penentuan Block Size (threads count per block) dan Grid Size (blocks count per size)
   Block size memiliki nilai perkalian dimensi x y z maksimal 1024. Karena ini adalah operasi pada matrix 2D, maka dimensi z akan dianggap 1. Kemudian karena ukuran matriks kelipatan 2^n, digunakan 2^n terbesar dimana 2^n * 2^n <= 1024, yaitu 32*32. Karena operasi matrix 2D, dimensi z grid size juga 1. Nilai x dan y diambil dari pembagian ceiling size dengan 32 (dimana 32 adalah dimensi block size). Oleh karena itu, block size (32,32,1)
