// miniweather_mpi.c - MPI with communication/computation breakdown
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

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

#define IDX(x,y,z,sx) ( ((x) * (NY) + (y)) * (NZ) + (z) )

static void init_local(double *grid, int lx, int gx0) {
    const int sx = lx + 2;
    for (int x = 0; x < sx; ++x) {
        for (int y = 0; y < NY; ++y) {
            for (int z = 0; z < NZ; ++z) {
                int gx = gx0 + (x - 1);
                if (gx < 0) gx = 0;
                grid[IDX(x,y,z,sx)] = (double)(gx + y + z);
            }
        }
    }
}

static void halo_exchange(double *grid, int lx, int left, int right, MPI_Comm comm) {
    const int sx = lx + 2;
    const int face_elems = NY * NZ;

    MPI_Sendrecv(&grid[IDX(1,    0,0,sx)], face_elems, MPI_DOUBLE, left,  100,
                 &grid[IDX(lx+1, 0,0,sx)], face_elems, MPI_DOUBLE, right, 100,
                 comm, MPI_STATUS_IGNORE);

    MPI_Sendrecv(&grid[IDX(lx, 0,0,sx)], face_elems, MPI_DOUBLE, right, 101,
                 &grid[IDX(0,  0,0,sx)], face_elems, MPI_DOUBLE, left,  101,
                 comm, MPI_STATUS_IGNORE);
}

static void step_update(double *restrict g, double *restrict ng, int lx) {
    const int sx = lx + 2;

    for (int x = 1; x <= lx; ++x) {
        for (int y = 1; y < NY - 1; ++y) {
            for (int z = 1; z < NZ - 1; ++z) {
                double xm = g[IDX(x-1,y,  z,  sx)];
                double xp = g[IDX(x+1,y,  z,  sx)];
                double ym = g[IDX(x,  y-1,z,  sx)];
                double yp = g[IDX(x,  y+1,z,  sx)];
                double zm = g[IDX(x,  y,  z-1,sx)];
                double zp = g[IDX(x,  y,  z+1,sx)];
                ng[IDX(x,y,z,sx)] = (xm + xp + ym + yp + zm + zp) / 6.0;
            }
        }
    }

    for (int x = 1; x <= lx; ++x) {
        for (int y = 1; y < NY - 1; ++y) {
            for (int z = 1; z < NZ - 1; ++z) {
                g[IDX(x,y,z,sx)] = ng[IDX(x,y,z,sx)];
            }
        }
    }
}

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    MPI_Comm comm = MPI_COMM_WORLD;

    int rank = 0, size = 1;
    MPI_Comm_rank(comm, &rank);
    MPI_Comm_size(comm, &size);

    if (size > NX) {
        if (rank == 0) {
            fprintf(stderr, "ERROR: size (%d) > NX (%d)\n", size, NX);
        }
        MPI_Abort(comm, 1);
    }

    const int base = NX / size;
    const int rem  = NX % size;
    const int lx  = base + ((rank == size - 1) ? rem : 0);
    const int gx0 = rank * base;

    const size_t slab_elems = (size_t)(lx + 2) * NY * NZ;
    double *grid     = (double*)malloc(slab_elems * sizeof(double));
    double *new_grid = (double*)malloc(slab_elems * sizeof(double));
    
    if (!grid || !new_grid) {
        if (rank == 0) fprintf(stderr, "Allocation failed\n");
        MPI_Abort(comm, 2);
    }

    init_local(grid, lx, gx0);

    const int left  = (rank == 0)        ? MPI_PROC_NULL : rank - 1;
    const int right = (rank == size - 1) ? MPI_PROC_NULL : rank + 1;

    // Timing variables
    double comm_time = 0.0;
    double comp_time = 0.0;

    MPI_Barrier(comm);
    const double t0 = MPI_Wtime();

    for (int t = 0; t < STEPS; ++t) {
        // Time communication
        double t_comm_start = MPI_Wtime();
        halo_exchange(grid, lx, left, right, comm);
        double t_comm_end = MPI_Wtime();
        comm_time += (t_comm_end - t_comm_start);
        
        // Time computation
        double t_comp_start = MPI_Wtime();
        step_update(grid, new_grid, lx);
        double t_comp_end = MPI_Wtime();
        comp_time += (t_comp_end - t_comp_start);
    }

    MPI_Barrier(comm);
    const double t1 = MPI_Wtime();
    const double local_elapsed = t1 - t0;

    // Checksum
    double local_sum = 0.0;
    {
        const int sx = lx + 2;
        for (int x = 1; x <= lx; ++x) {
            for (int y = 0; y < NY; ++y) {
                for (int z = 0; z < NZ; ++z) {
                    local_sum += grid[IDX(x,y,z,sx)];
                }
            }
        }
    }

    // Reductions
    double global_sum = 0.0;
    double max_elapsed = 0.0;
    double max_comm_time = 0.0;
    double max_comp_time = 0.0;
    
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, comm);
    MPI_Reduce(&local_elapsed, &max_elapsed, 1, MPI_DOUBLE, MPI_MAX, 0, comm);
    MPI_Reduce(&comm_time, &max_comm_time, 1, MPI_DOUBLE, MPI_MAX, 0, comm);
    MPI_Reduce(&comp_time, &max_comp_time, 1, MPI_DOUBLE, MPI_MAX, 0, comm);

    if (rank == 0) {
        size_t total_cells = (size_t)NX * NY * NZ;
        double throughput_steps = STEPS / max_elapsed;
        double throughput_cells = (total_cells * STEPS) / max_elapsed;
        double comm_pct = 100.0 * max_comm_time / max_elapsed;
        double comp_pct = 100.0 * max_comp_time / max_elapsed;
        
        printf("METRICS: VERSION=mpi RANKS=%d GRID=%dx%dx%d STEPS=%d TIME=%.6f "
               "COMM_TIME=%.6f COMP_TIME=%.6f COMM_PCT=%.2f COMP_PCT=%.2f "
               "THROUGHPUT_STEPS=%.2f THROUGHPUT_CELLS=%.2e CHECKSUM=%.10e\n",
               size, NX, NY, NZ, STEPS, max_elapsed,
               max_comm_time, max_comp_time, comm_pct, comp_pct,
               throughput_steps, throughput_cells, global_sum);
    }

    free(new_grid);
    free(grid);
    MPI_Finalize();
    return 0;
}