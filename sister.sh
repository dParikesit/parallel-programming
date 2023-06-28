#! /bin/bash
USERNAME="k02-02"
HOSTS="xx.xxx.xxx.xxx xx.xxx.xxx.xxx xx.xxx.xxx.xxx"
SIZES="64"

DIR_HOSTNAME="./hostfile"
DIR_SERIAL="src/serial/c/serial.c"
DIR_OPENMPI="src/open-mpi/mpi.c"
DIR_OPENMP="src/open-mp/mp.c"

COMPILE_SERIAL="gcc ./serial.c -o ./serial -lm"
COMPILE_OPENMPI="mpicc ./mpi.c -o ./mpi -lm"
COMPILE_OPENMP="gcc ./mp.c --openmp -o ./mp -lm"

echo "Compiling serial and cuda on local..."
make serial
make parallel-cuda
echo ""

echo "Copying files to hosts and compiling..."
for HOSTNAME in ${HOSTS}; do
    echo "Copying files to ${HOSTNAME}..."
    scp ${DIR_HOSTNAME} ${USERNAME}@${HOSTNAME}:~
    scp ${DIR_SERIAL} ${USERNAME}@${HOSTNAME}:~
    scp ${DIR_OPENMPI} ${USERNAME}@${HOSTNAME}:~
    for SIZE in ${SIZES}; do
        scp ./test_case/${SIZE}.txt ${USERNAME}@${HOSTNAME}:~
    done
    echo "Compiling files on ${HOSTNAME}..."
    ssh ${USERNAME}@${HOSTNAME} "${COMPILE_SERIAL} && ${COMPILE_OPENMPI} && ${COMPILE_OPENMP}"
    echo " "
done

echo "Running tests..."
for SIZE in ${SIZES}; do
    echo "Running tests for ${SIZE}..."

    echo "Running serial on server..."
    ssh ${USERNAME}@34.126.112.192 "time ./serial < ./${SIZE}.txt > ./out-serial-${SIZE}.txt"

    echo "Running serial on local..."
    time ./bin/serial < ./test_case/${SIZE}.txt > ./out-serial-${SIZE}.txt

    echo "Running open-mpi..."
    ssh ${USERNAME}@34.126.112.192 "time mpirun -np 4 --hostfile ./hostfile ./mpi < ./${SIZE}.txt > ./out-mpi-${SIZE}.txt"

    echo "Running open-mp..."
    ssh ${USERNAME}@34.126.112.192 "time ./mp < ./${SIZE}.txt > ./out-mp-${SIZE}.txt"
    
    echo "Running serial on cuda..."
    time ./bin/cuda < ./test_case/${SIZE}.txt > ./out-cuda-${SIZE}.txt
done