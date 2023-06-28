#! /bin/bash

dir=$(pwd)
file1=$dir/out-serial.txt
file2=$dir/out-parallel-cuda.txt

if [ -f "$file1" ] ; then
    rm "$file1"
fi
if [ -f "$file2" ] ; then
    rm "$file2"
fi

make serial
time $dir/bin/serial < $dir/test_case/$1.txt > $dir/out-serial.txt

make parallel-cuda
echo Compile done
# compute-sanitizer $dir/bin/cuda --launch-timeout 0 < $dir/test_case/$1.txt > $dir/out-parallel-cuda.txt
time $dir/bin/cuda < $dir/test_case/$1.txt > $dir/out-parallel-cuda.txt
