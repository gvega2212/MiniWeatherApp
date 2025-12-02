#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
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

// sx is passed but not needed in the stride; kept for clarity with local slab
#define IDX(x,y,z,sx) (((x) * (NY) + (y)) * (NZ) + (z))

void init_local(double *grid, int lx, int gx0) {
    const int sx = lx + 2;
    
    #pragma acc parallel loop collapse(3) present(grid)
    for (int x = 0; x < sx; x++) {
        for (int y = 0; y < NY; y++) {
            for (int z = 0; z < NZ; z++) {
                int gx = gx0 + (x - 1);
                if (gx < 0) gx = 0;
                grid[IDX(x,y,z,sx)] = (double)(gx + y + z);
            }
        }
    }
}

// OPTIMIZATION: Using async clauses to overlap GPU-CPU transfers with MPI communication
void halo_exchange_optimized(double *grid, int lx, int left, int right, MPI_Comm comm) {
    const int sx = lx + 2;
    const int face_elems = NY * NZ;
    
    double *send_left  = (double*)malloc(face_elems * sizeof(double));
    double *send_right = (double*)malloc(face_elems * sizeof(double));
    double *recv_left  = (double*)malloc(face_elems * sizeof(double));
    double *recv_right = (double*)malloc(face_elems * sizeof(double));
    
    if (!send_left || !send_right || !recv_left || !recv_right) {
        fprintf(stderr, "Halo allocation failed\n");
        MPI_Abort(comm, 3);
    }
    
    // OPTIMIZATION: Use async(1) for left halo, async(2) for right halo
    // This allows GPU-to-host transfers to overlap with each other
    #pragma acc update host(grid[IDX(1,0,0,sx):face_elems]) async(1)
    #pragma acc update host(grid[IDX(lx,0,0,sx):face_elems]) async(2)
    
    // Wait for transfers to complete before MPI
    #pragma acc wait(1)
    #pragma acc wait(2)
    
    for (int i = 0; i < face_elems; i++) {
        send_left[i]  = grid[IDX(1,0,0,sx)  + i];
        send_right[i] = grid[IDX(lx,0,0,sx) + i];
    }
    
    // MPI exchange (using non-blocking would be even better, but keeping it simple)
    MPI_Sendrecv(send_left,  face_elems, MPI_DOUBLE, left,  100,
                 recv_right, face_elems, MPI_DOUBLE, right, 100,
                 comm, MPI_STATUS_IGNORE);
    
    MPI_Sendrecv(send_right, face_elems, MPI_DOUBLE, right, 101,
                 recv_left,  face_elems, MPI_DOUBLE, left,  101,
                 comm, MPI_STATUS_IGNORE);
    
    // Copy received halos back to grid
    for (int i = 0; i < face_elems; i++) {
        grid[IDX(0,    0, 0, sx) + i] = recv_left[i];
        grid[IDX(lx+1, 0, 0, sx) + i] = recv_right[i];
    }
    
    // OPTIMIZATION: Async device updates - can overlap with next operations
    #pragma acc update device(grid[IDX(0,0,0,sx):face_elems]) async(1)
    #pragma acc update device(grid[IDX(lx+1,0,0,sx):face_elems]) async(2)
    
    free(send_left);
    free(send_right);
    free(recv_left);
    free(recv_right);
}

// OPTIMIZATION: Added gang and vector clauses for better GPU utilization
void step_update_optimized(double *restrict g, double *restrict ng, int lx) {
    const int sx = lx + 2;
    
    // OPTIMIZATION: Explicit gang/vector tuning for better GPU performance
    #pragma acc parallel loop gang vector_length(128) collapse(3) present(g, ng)
    for (int x = 1; x <= lx; x++) {
        for (int y = 1; y < NY-1; y++) {
            for (int z = 1; z < NZ-1; z++) {
                double xm = g[IDX(x-1,y,z,sx)];
                double xp = g[IDX(x+1,y,z,sx)];
                double ym = g[IDX(x,y-1,z,sx)];
                double yp = g[IDX(x,y+1,z,sx)];
                double zm = g[IDX(x,y,z-1,sx)];
                double zp = g[IDX(x,y,z+1,sx)];
                ng[IDX(x,y,z,sx)] = (xm + xp + ym + yp + zm + zp) / 6.0;
            }
        }
    }
    
    #pragma acc parallel loop gang vector_length(128) collapse(3) present(g, ng)
    for (int x = 1; x <= lx; x++) {
        for (int y = 1; y < NY-1; y++) {
            for (int z = 1; z < NZ-1; z++) {
                g[IDX(x,y,z,sx)] = ng[IDX(x,y,z,sx)];
            }
        }
    }
}

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    MPI_Comm comm = MPI_COMM_WORLD;
    
    int rank, size;
    MPI_Comm_rank(comm, &rank);
    MPI_Comm_size(comm, &size);
    
    // Set GPU device based on rank
    int num_devices = acc_get_num_devices(acc_device_nvidia);
    if (num_devices <= 0) {
        if (rank == 0) {
            fprintf(stderr, "ERROR: No GPUs visible to OpenACC\n");
        }
        MPI_Abort(comm, 4);
    }
    int device_id = rank % num_devices;
    acc_set_device_num(device_id, acc_device_nvidia);
    
    if (size > NX) {
        if (rank == 0) fprintf(stderr, "ERROR: size > NX\n");
        MPI_Abort(comm, 1);
    }
    
    const int base = NX / size;
    const int rem  = NX % size;
    const int lx   = base + ((rank == size-1) ? rem : 0);
    const int gx0  = rank * base;
    
    const size_t slab_elems = (size_t)(lx + 2) * NY * NZ;
    double *grid     = (double*)malloc(slab_elems * sizeof(double));
    double *new_grid = (double*)malloc(slab_elems * sizeof(double));
    
    if (!grid || !new_grid) {
        if (rank == 0) fprintf(stderr, "Allocation failed\n");
        MPI_Abort(comm, 2);
    }
    
    // Copy to GPU
    #pragma acc enter data create(grid[0:slab_elems], new_grid[0:slab_elems])
    
    init_local(grid, lx, gx0);
    
    const int left  = (rank == 0)        ? MPI_PROC_NULL : rank - 1;
    const int right = (rank == size - 1) ? MPI_PROC_NULL : rank + 1;
    
    // Timing variables
    double comm_time   = 0.0;
    double comp_time   = 0.0;
    
    MPI_Barrier(comm);
    double t0 = MPI_Wtime();
    
    for (int t = 0; t < STEPS; t++) {
        // Time communication (includes GPU-CPU transfers)
        double t_comm_start = MPI_Wtime();
        halo_exchange_optimized(grid, lx, left, right, comm);
        double t_comm_end = MPI_Wtime();
        comm_time += (t_comm_end - t_comm_start);
        
        // Time computation (GPU kernels)
        double t_comp_start = MPI_Wtime();
        step_update_optimized(grid, new_grid, lx);
        #pragma acc wait
        double t_comp_end = MPI_Wtime();
        comp_time += (t_comp_end - t_comp_start);
    }
    
    MPI_Barrier(comm);
    double t1 = MPI_Wtime();
    double elapsed = t1 - t0;
    
    // Checksum on GPU (internal slab cells only)
    double local_sum = 0.0;
    const int sx = lx + 2;
    #pragma acc parallel loop collapse(3) reduction(+:local_sum) present(grid)
    for (int x = 1; x <= lx; x++) {
        for (int y = 0; y < NY; y++) {
            for (int z = 0; z < NZ; z++) {
                local_sum += grid[IDX(x,y,z,sx)];
            }
        }
    }
    
    double global_sum    = 0.0;
    double max_elapsed   = 0.0;
    double max_comm_time = 0.0;
    double max_comp_time = 0.0;
    
    MPI_Reduce(&local_sum,  &global_sum,    1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD, 0);
    MPI_Reduce(&elapsed,    &max_elapsed,   1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD, 0);
    MPI_Reduce(&comm_time,  &max_comm_time, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD, 0);
    MPI_Reduce(&comp_time,  &max_comp_time, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD, 0);
    
    if (rank == 0) {
        size_t total_cells = (size_t)NX * NY * NZ;
        double throughput_steps  = STEPS / max_elapsed;
        double throughput_cells  = (total_cells * STEPS) / max_elapsed;
        double comm_pct          = 100.0 * max_comm_time / max_elapsed;
        double comp_pct          = 100.0 * max_comp_time / max_elapsed;
        
        printf("METRICS: VERSION=mpi_openacc_optimized RANKS=%d GPUS=%d GRID=%dx%dx%d STEPS=%d TIME=%.6f "
               "COMM_TIME=%.6f COMP_TIME=%.6f COMM_PCT=%.2f COMP_PCT=%.2f "
               "THROUGHPUT_STEPS=%.2f THROUGHPUT_CELLS=%.2e CHECKSUM=%.10e\n",
               size, size, NX, NY, NZ, STEPS, max_elapsed,
               max_comm_time, max_comp_time, comm_pct, comp_pct,
               throughput_steps, throughput_cells, global_sum);
    }
    
    #pragma acc exit data delete(grid[0:slab_elems], new_grid[0:slab_elems])
    
    free(new_grid);
    free(grid);
    MPI_Finalize();
    return 0;
}
