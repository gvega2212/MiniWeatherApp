#include <mpi.h>
#include <iostream>
#include <vector>
using namespace std;

#define NX 8
#define NY 8
#define NZ 8
#define STEPS 5

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int nx_local = NX / size;
    int start_x = rank * nx_local;
    int end_x = start_x + nx_local - 1;

    vector<vector<vector<double>>> grid(
        nx_local, vector<vector<double>>(NY, vector<double>(NZ, 0.0))
    );

    // Initialize
    for (int i = 0; i < nx_local; i++)
        for (int j = 0; j < NY; j++)
            for (int k = 0; k < NZ; k++)
                grid[i][j][k] = rank + 0.1 * i;

    // Dummy compute loop
    for (int t = 0; t < STEPS; t++)
        for (int i = 0; i < nx_local; i++)
            for (int j = 0; j < NY; j++)
                for (int k = 0; k < NZ; k++)
                    grid[i][j][k] += 0.01 * rank;

    cout << "Rank " << rank << " handled X[" << start_x << ":" << end_x
     << "]  Local mean=" << grid[nx_local/2][NY/2][NZ/2] << endl;


    MPI_Finalize();
    return 0;
}