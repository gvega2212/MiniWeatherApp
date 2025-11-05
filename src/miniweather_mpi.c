#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#define NX 8
#define NY 8
#define NZ 8
#define STEPS 10

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);  // Start MPI

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    printf("Hello from rank %d of %d\n", rank, size);

    MPI_Finalize();  // End MPI
    return 0;
}
