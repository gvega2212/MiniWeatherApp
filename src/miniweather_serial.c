#include <stdio.h>
#include <stdlib.h>

#define NX 8
#define NY 8
#define NZ 8
#define STEPS 10

int main() {
    double grid[NX][NY][NZ] = {0};  

    // Initialize grid with some values
    for (int x = 0; x < NX; x++)
        for (int y = 0; y < NY; y++)
            for (int z = 0; z < NZ; z++)
                grid[x][y][z] = x + y + z;

    // Time evolution loop
    for (int t = 0; t < STEPS; t++) {
        for (int x = 1; x < NX-1; x++)
            for (int y = 1; y < NY-1; y++)
                for (int z = 1; z < NZ-1; z++)
                    grid[x][y][z] += (grid[x-1][y][z] + grid[x+1][y][z] +
                                       grid[x][y-1][z] + grid[x][y+1][z] +
                                       grid[x][y][z-1] + grid[x][y][z+1]) / 6.0;
    }

    // Save results to CSV
    FILE *f = fopen("../results/baseline/output_serial.csv", "w");
    if (!f) {
        printf("Error opening file!\n");
        return 1;
    }

    for (int x = 0; x < NX; x++)
        for (int y = 0; y < NY; y++)
            for (int z = 0; z < NZ; z++)
                fprintf(f, "%d,%d,%d,%.2f\n", x, y, z, grid[x][y][z]);

    fclose(f);
    printf("Simulation complete! Results saved to results/output.csv\n");
    return 0;
}

