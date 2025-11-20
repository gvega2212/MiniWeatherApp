// miniweather_openmp.c - OpenMP with comprehensive metrics
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <sys/time.h>

#ifndef NX
#define NX 64
#endif
#ifndef NY
#define NY 64
#endif
#ifndef NZ
#define NZ 64
#endif
#ifndef STEPS
#define STEPS 20
#endif

static double get_wtime() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec * 1e-6;
}

int main() {
    double (*grid)[NY][NZ] = malloc(sizeof(double[NX][NY][NZ]));
    double (*new_grid)[NY][NZ] = malloc(sizeof(double[NX][NY][NZ]));
    
    if (!grid || !new_grid) {
        fprintf(stderr, "Allocation failed\n");
        return 1;
    }
    
    int num_threads = 1;
    #pragma omp parallel
    {
        #pragma omp master
        num_threads = omp_get_num_threads();
    }
    
    // Initialize grid
    #pragma omp parallel for collapse(3)
    for (int x = 0; x < NX; x++)
        for (int y = 0; y < NY; y++)
            for (int z = 0; z < NZ; z++)
                grid[x][y][z] = (double)(x + y + z);
    
    // Timing
    double t0 = get_wtime();
    
    // Time evolution loop
    for (int t = 0; t < STEPS; t++) {
        // 6-point stencil update
        #pragma omp parallel for collapse(3)
        for (int x = 1; x < NX-1; x++)
            for (int y = 1; y < NY-1; y++)
                for (int z = 1; z < NZ-1; z++)
                    new_grid[x][y][z] = (grid[x-1][y][z] + grid[x+1][y][z] +
                                         grid[x][y-1][z] + grid[x][y+1][z] +
                                         grid[x][y][z-1] + grid[x][y][z+1]) / 6.0;
        
        // Copy back
        #pragma omp parallel for collapse(3)
        for (int x = 1; x < NX-1; x++)
            for (int y = 1; y < NY-1; y++)
                for (int z = 1; z < NZ-1; z++)
                    grid[x][y][z] = new_grid[x][y][z];
    }
    
    double t1 = get_wtime();
    double elapsed = t1 - t0;
    
    // Calculate metrics
    size_t total_cells = (size_t)NX * NY * NZ;
    double throughput_steps = STEPS / elapsed;
    double throughput_cells = (total_cells * STEPS) / elapsed;
    
    // Checksum
    double sum = 0.0;
    #pragma omp parallel for collapse(3) reduction(+:sum)
    for (int x = 0; x < NX; x++)
        for (int y = 0; y < NY; y++)
            for (int z = 0; z < NZ; z++)
                sum += grid[x][y][z];
    
    printf("METRICS: VERSION=openmp THREADS=%d GRID=%dx%dx%d STEPS=%d TIME=%.6f "
           "THROUGHPUT_STEPS=%.2f THROUGHPUT_CELLS=%.2e CHECKSUM=%.10e\n",
           num_threads, NX, NY, NZ, STEPS, elapsed, throughput_steps, throughput_cells, sum);
    
    free(new_grid);
    free(grid);
    return 0;
}