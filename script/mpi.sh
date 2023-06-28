#! /bin/bash

dir=$(pwd)
file1=$dir/out-serial-mpi.txt
file2=$dir/out-parallel-mpi.txt

if [ -f "$file1" ] ; then
    rm "$file1"
fi
if [ -f "$file2" ] ; then
    rm "$file2"
fi

make serial
time mpirun -v -n 1 $dir/bin/serial < $dir/test_case/$1.txt > $dir/out-serial-mpi.txt

make parallel-mpi
time mpirun -v -n 4 $dir/bin/mpi < $dir/test_case/$1.txt > $dir/out-parallel-mpi.txt