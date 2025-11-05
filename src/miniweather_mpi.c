// miniweather_mpi.c
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#ifdef _OPENMP
  #include <omp.h>
#endif

// ---- Problem size (override at compile time with -DNX=..., etc.)
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

// Flat index for a 3D slab with size sx x NY x NZ (sx == local_x + 2 halos)
#define IDX(x,y,z,sx) ( ((x) * (NY) + (y)) * (NZ) + (z) )

static void init_local(double *grid, int lx, int gx0) {
  // Initialize including halos (x in [0..lx+1]) so values are defined everywhere.
  const int sx = lx + 2;
  #pragma omp parallel for collapse(3) if(lx*NY*NZ > 32768)
  for (int x = 0; x < sx; ++x) {
    for (int y = 0; y < NY; ++y) {
      for (int z = 0; z < NZ; ++z) {
        int gx = gx0 + (x - 1);                 // global X for interior cells
        if (gx < 0) gx = 0;                      // clamp for edges
        double v = (double)(gx + y + z);        // simple deterministic field
        grid[IDX(x,y,z,sx)] = v;
      }
    }
  }
}

static void halo_exchange(double *grid, int lx, int left, int right, MPI_Comm comm) {
  // Exchange X faces: each face is NY*NZ doubles.
  const int sx = lx + 2;
  const int face_elems = NY * NZ;

  // Send interior x=1 → left, recv right halo at x=lx+1 ← right
  MPI_Sendrecv(&grid[IDX(1,    0,0,sx)], face_elems, MPI_DOUBLE, left,  100,
               &grid[IDX(lx+1, 0,0,sx)], face_elems, MPI_DOUBLE, right, 100,
               comm, MPI_STATUS_IGNORE);

  // Send interior x=lx → right, recv left halo at x=0 ← left
  MPI_Sendrecv(&grid[IDX(lx, 0,0,sx)], face_elems, MPI_DOUBLE, right, 101,
               &grid[IDX(0,  0,0,sx)], face_elems, MPI_DOUBLE, left,  101,
               comm, MPI_STATUS_IGNORE);
}

static void step_update(double *restrict g, double *restrict ng, int lx) {
  // 6-point stencil on interior (exclude halos in X and borders in Y/Z)
  const int sx = lx + 2;

  #pragma omp parallel for collapse(3) if(lx*NY*NZ > 32768)
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

  // Copy updated interior back
  #pragma omp parallel for collapse(3) if(lx*NY*NZ > 32768)
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

  // Simple guard: require size <= NX (so each rank can own at least some X)
  if (size > NX) {
    if (rank == 0) {
      fprintf(stderr, "ERROR: size (%d) > NX (%d). Reduce ranks or increase NX.\n", size, NX);
    }
    MPI_Abort(comm, 1);
  }

  // 1D slab decomposition in X; remainder given to the LAST rank.
  const int base = NX / size;
  const int rem  = NX % size;

  const int lx  = base + ((rank == size - 1) ? rem : 0); // local interior length
  const int gx0 = rank * base;                            // starting global X for this rank
  const int gx1 = gx0 + lx - 1;                           // ending global X (inclusive)

  // Allocate local slabs with 2 halos in X
  const size_t slab_elems = (size_t)(lx + 2) * NY * NZ;
  double *grid     = (double*)malloc(slab_elems * sizeof(double));
  double *new_grid = (double*)malloc(slab_elems * sizeof(double));
  if (!grid || !new_grid) {
    if (rank == 0) fprintf(stderr, "Allocation failed\n");
    MPI_Abort(comm, 2);
  }

  // Initialize local slab (including halos)
  init_local(grid, lx, gx0);

  // Neighbor ranks (edges use MPI_PROC_NULL → Sendrecv becomes a no-op on that side)
  const int left  = (rank == 0)        ? MPI_PROC_NULL : rank - 1;
  const int right = (rank == size - 1) ? MPI_PROC_NULL : rank + 1;

  // --- Timing
  MPI_Barrier(comm);
  const double t0 = MPI_Wtime();

  // Time stepping
  for (int t = 0; t < STEPS; ++t) {
    halo_exchange(grid, lx, left, right, comm);
    step_update(grid, new_grid, lx);
  }

  MPI_Barrier(comm);
  const double t1 = MPI_Wtime();
  const double local_elapsed = t1 - t0;

  // Correctness metric: sum of interior cells owned by this rank
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

  // Reductions: global checksum and maximum elapsed time across ranks
  double global_sum = 0.0;
  double max_elapsed = 0.0;
  MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, comm);
  MPI_Reduce(&local_elapsed, &max_elapsed, 1, MPI_DOUBLE, MPI_MAX, 0, comm);

  // Optional per-rank debug (commented to keep logs clean)
  // printf("Rank %d owns X[%d:%d] lx=%d time=%.6f s\n", rank, gx0, gx1, lx, local_elapsed);

  if (rank == 0) {
    printf("GLOBAL_SUM=%.10e RANKS=%d GRID=%dx%dx%d STEPS=%d TIME=%.6f s\n",
           global_sum, size, NX, NY, NZ, STEPS, max_elapsed);
    fflush(stdout);
  }

  free(new_grid);
  free(grid);
  MPI_Finalize();
  return 0;
}
