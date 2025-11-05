#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#define NX 8
#define NY 8
#define NZ 8
#define STEPS 10

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // Determine subdomain per rank
    int chunk = NX / size;
    int start = rank * chunk;
    int end = start + chunk - 1;

    double grid[chunk+2][NY][NZ];      // +2 for halo layers
    double new_grid[chunk+2][NY][NZ];

    // Initialize grid (including halos)
    for (int x = 0; x < chunk+2; x++)
        for (int y = 0; y < NY; y++)
            for (int z = 0; z < NZ; z++)
                grid[x][y][z] = start + x - 1; // simple values for testing

    int left = (rank == 0) ? MPI_PROC_NULL : rank - 1;
    int right = (rank == size-1) ? MPI_PROC_NULL : rank + 1;

    for (int t = 0; t < STEPS; t++) {
        // Halo exchange
        MPI_Sendrecv(&grid[1][0][0], NY*NZ, MPI_DOUBLE, left, 0,
                     &grid[chunk+1][0][0], NY*NZ, MPI_DOUBLE, right, 0,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        MPI_Sendrecv(&grid[chunk][0][0], NY*NZ, MPI_DOUBLE, right, 1,
                     &grid[0][0][0], NY*NZ, MPI_DOUBLE, left, 1,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        // Update inner points (excluding halos)
        for (int x = 1; x <= chunk; x++)
            for (int y = 1; y < NY-1; y++)
                for (int z = 1; z < NZ-1; z++)
                    new_grid[x][y][z] = (grid[x-1][y][z] + grid[x+1][y][z] +
                                          grid[x][y-1][z] + grid[x][y+1][z] +
                                          grid[x][y][z-1] + grid[x][y][z+1]) / 6.0;

        // Copy new values back
        for (int x = 1; x <= chunk; x++)
            for (int y = 1; y < NY-1; y++)
                for (int z = 1; z < NZ-1; z++)
                    grid[x][y][z] = new_grid[x][y][z];
    }

    // Print rank summary
    double local_sum = 0;
    for (int x = 1; x <= chunk; x++)
        for (int y = 0; y < NY; y++)
            for (int z = 0; z < NZ; z++)
                local_sum += grid[x][y][z];

    printf("Rank %d handled X[%d:%d]  Local mean=%.2f\n", rank, start, end, local_sum/(chunk*NY*NZ));

    MPI_Finalize();
    return 0;
}