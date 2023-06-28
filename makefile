OUTPUT_FOLDER = bin
SAMPLE_INPUT = src/sample
SAMPLE_OUTPUT = bin/sample
SERIAL_FOLDER = src/serial
OPEN_MPI_FOLDER = src/open-mpi
OPEN_MP_FOLDER = src/open-mp
CUDA_FOLDER = src/cuda

all: sample serial parallel

serial:
	gcc $(SERIAL_FOLDER)/c/serial.c -o $(OUTPUT_FOLDER)/serial -lm

serial-cpp:
	g++ $(SERIAL_FOLDER)/c++/serial.cpp -o $(OUTPUT_FOLDER)/serial -lm

parallel: parallel-mpi parallel-mp parallel-cuda

parallel-mpi:
	mpicc $(OPEN_MPI_FOLDER)/mpi.c -o $(OUTPUT_FOLDER)/mpi -lm

parallel-mp:
	gcc $(OPEN_MP_FOLDER)/mp.c --openmp -o $(OUTPUT_FOLDER)/mp -lm

parallel-cuda: 
	nvcc $(CUDA_FOLDER)/cuda.cu -o $(OUTPUT_FOLDER)/cuda -arch=sm_86 -rdc=true -lcudadevrt

sample: sample-mpi sample-mp sample-cuda

sample-mpi:
	mkdir -p $(SAMPLE_OUTPUT) && mpicc $(SAMPLE_INPUT)/mpi.c -o $(SAMPLE_OUTPUT)/mpi

sample-mp:
	mkdir -p $(SAMPLE_OUTPUT) && gcc $(SAMPLE_INPUT)/mp.c -fopenmp -o $(SAMPLE_OUTPUT)/mp

sample-cuda:
	mkdir -p $(SAMPLE_OUTPUT) && nvcc $(SAMPLE_INPUT)/cuda.cu -o $(SAMPLE_OUTPUT)/cuda

clean:
	rm $(OUTPUT_FOLDER)/*