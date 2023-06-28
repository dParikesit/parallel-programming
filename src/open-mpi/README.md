# Open MPI
## Penjelasan Cara Kerja Paralelisasi Program
Paralelisasi program adalah teknik untuk memecah program menjadi bagian-bagian yang dapat dieksekusi secara bersamaan secara independen. Bagian-bagian tersebut akan dieksekusi pada beberapa processor atau core sebuah komputer atau cluster. Tujuan utama dari paralelisasi program ini adalah untuk mempercepat waktu eksekusi program dan meningkatkan efisiensi penggunaan sumber daya komputer. <br/>
Paralelisasi program dapat dilakukan dengan terlebih dulu menganalisis program untuk menemukan bagian program mana yang dapat dieksekusi secara paralel dan independen antara satu sama lain. Selain itu, perlu diperhatikan cara untuk menggabungkan hasil dari setiap bagian paralel program. <br/>
Setelah desain dan algoritma program paralel telah didesain, program dapat diimplementasikan dengan teknologi paralel, pada Tucil 1 ini menggunakan Open MPI. Bagian-bagian program yang telah dipisahkan akan dieksekusi secara paralel pada beberapa processor atau core komputer. Program yang telah diimplementasikan akan memiliki waktu eksekusi yang lebih cepat dibandingkan program yang dieksekusi secara serial. Namun, perlu diuji untuk memastikan hasil eksekusi antara program serial dan paralel adalah sama.


## Penjelasan Cara Program Membagikan Data Antar-proses atau Antar-thread dan Alasan Pemilihan Skema
### Skema Modifikasi Program
Skema modifikasi yang dilakukan untuk mengubah kode serial ke paralel adalah sebagai berikut:
1. Mengubah tipe data struct Matrix. Atribut mat (matrix) diubah dari yang awalnya array 2D menjadi array dinamis 1D. Hal ini dilakukan untuk mempermudah passing matrix ke process lain
2. Membuat variabel struct Matrix source pada semua process. Read input hanya dilakukan pada process ke-0.
3. Process ke-0 sudah memiliki semua data matrix beserta ukuran matrix nya. Selanjutnya, akan dilakukan broadcast UKURAN MATRIX ke semua process yang ada.
4. Process lain yang sudah mendapat ukuran matrix  dapat melakukan malloc pada atribut mat pada struct Matrix source.
5. Process ke-0 kemudian melakukan broadcast atribut mat ke process lainnya. Pada akhir tahap ini, semua process sudah memiliki data matrix yang akan diproses.
```
Pada tahap ini, perhitungan DFT dimulai. Perhitungan DFT pada dasarnya adalah proses looping semua elemen matrix (size*size), kemudian pada tiap looping tersebut dilakukan pemanggilan fungsi DFT. Fungsi DFT merupakan fungsi yang independen pada tiap pemanggilannya. Oleh karena itu, pemanggilan fungsi DFT bisa diparalelisasi pada semua process.
```
6. Dilakukan pembagian perhitungan fungsi DFT secara merata pada semua process. Pada matrix berukuran size*size, tiap process akan menghitung sebanyak (size/4)*size.
7. Tujuan akhir dari program DFT ini adalah untuk mencari average dari perhitungan fungsi DFT pada semua elemen matrix. Average adalah penjumlahan semua elemen hasil fungsi DFT dibagi dengan size matrix. Karena yang dibutuhkan oleh output akhir hanya jumlah perhitungan fungsi DFT, maka bisa digunakan fungsi MPI_Reduce untuk langsung menjumlahkan seluruh hasil fungsi DFT ke process 0.
8. Untuk mendapatkan average, lakukan pembagian jumlah fungsi DFT kemudian dibagi dengan size matrix.
9. (Tambahan) Karena di QNA diperbolehkan print sebagian hasil perhitungan saja, maka diputuskan untuk hanya mengirimkan jumlah hasil saja, tanpa hasil masing-masing perhitungan.

### Alasan Pemilihan Skema
Skema modifikasi program dilakukan untuk mempermudah passing atribut antara satu proses ke proses lain. Hal in dilakukan untuk memastikan bahwa setiap proses akan memiliki atribut dengan data yang sama sehingga hasil program akan sama antara program serial dan paralel.