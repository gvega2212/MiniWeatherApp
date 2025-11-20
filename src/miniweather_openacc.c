// miniweather_openacc.c - Single GPU with OpenACC and metrics
#include <stdio.h>
#include <stdlib.h>
#include <openacc.h>

#ifndef NX
#define NX 256
#endif
#ifndef NY
#define NY 256
#endif
#ifndef NZ
#define NZ 256
#endif
#ifndef STEPS
#define STEPS 100
#endif

#define IDX(x,y,z) (((x) * (NY) + (y)) * (NZ) + (z))

void init_grid(double *grid) {
    #pragma acc parallel loop collapse(3) present(grid)
    for (int x = 0; x < NX; x++) {
        for (int y = 0; y < NY; y++) {
            for (int z = 0; z < NZ; z++) {
                grid[IDX(x,y,z)] = (double)(x + y + z);
            }
        }
    }
}

void step_update(double *restrict grid, double *restrict new_grid) {
    #pragma acc parallel loop collapse(3) present(grid, new_grid)
    for (int x = 1; x < NX-1; x++) {
        for (int y = 1; y < NY-1; y++) {
            for (int z = 1; z < NZ-1; z++) {
                double xm = grid[IDX(x-1, y, z)];
                double xp = grid[IDX(x+1, y, z)];
                double ym = grid[IDX(x, y-1, z)];
                double yp = grid[IDX(x, y+1, z)];
                double zm = grid[IDX(x, y, z-1)];
                double zp = grid[IDX(x, y, z+1)];
                
                new_grid[IDX(x,y,z)] = (xm + xp + ym + yp + zm + zp) / 6.0;
            }
        }
    }
    
    #pragma acc parallel loop collapse(3) present(grid, new_grid)
    for (int x = 1; x < NX-1; x++) {
        for (int y = 1; y < NY-1; y++) {
            for (int z = 1; z < NZ-1; z++) {
                grid[IDX(x,y,z)] = new_grid[IDX(x,y,z)];
            }
        }
    }
}

int main(int argc, char **argv) {
    const size_t elems = (size_t)NX * NY * NZ;
    double *grid = (double*)malloc(elems * sizeof(double));
    double *new_grid = (double*)malloc(elems * sizeof(double));
    
    if (!grid || !new_grid) {
        fprintf(stderr, "Allocation failed\n");
        return 1;
    }
    
    // Copy data to GPU
    #pragma acc enter data create(grid[0:elems], new_grid[0:elems])
    
    init_grid(grid);
    
    // Timing
    double t0 = acc_get_wall_time();
    double kernel_time = 0.0;
    
    for (int t = 0; t < STEPS; t++) {
        double t_kernel_start = acc_get_wall_time();
        step_update(grid, new_grid);
        #pragma acc wait
        double t_kernel_end = acc_get_wall_time();
        kernel_time += (t_kernel_end - t_kernel_start);
    }
    
    double t1 = acc_get_wall_time();
    double elapsed = t1 - t0;
    
    // Calculate checksum on GPU
    double sum = 0.0;
    #pragma acc parallel loop collapse(3) reduction(+:sum) present(grid)
    for (int x = 0; x < NX; x++) {
        for (int y = 0; y < NY; y++) {
            for (int z = 0; z < NZ; z++) {
                sum += grid[IDX(x,y,z)];
            }
        }
    }
    
    // Copy results back from GPU
    #pragma acc exit data copyout(grid[0:elems]) delete(new_grid[0:elems])
    
    // Calculate metrics
    size_t total_cells = (size_t)NX * NY * NZ;
    double throughput_steps = STEPS / elapsed;
    double throughput_cells = (total_cells * STEPS) / elapsed;
    double kernel_pct = 100.0 * kernel_time / elapsed;
    
    printf("METRICS: VERSION=openacc GPUS=1 GRID=%dx%dx%d STEPS=%d TIME=%.6f "
           "KERNEL_TIME=%.6f KERNEL_PCT=%.2f "
           "THROUGHPUT_STEPS=%.2f THROUGHPUT_CELLS=%.2e CHECKSUM=%.10e\n",
           NX, NY, NZ, STEPS, elapsed, kernel_time, kernel_pct,
           throughput_steps, throughput_cells, sum);
    
    free(new_grid);
    free(grid);
    return 0;
}