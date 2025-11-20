#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <sys/stat.h>
#include <errno.h>
#include <omp.h>

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
#define STEPS 10
#endif

#define IDX(i,j,k) ((size_t)(i) + (size_t)(NX)*((size_t)(j) + (size_t)(NY)*(size_t)(k)))

static double now_sec(void) {
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return ts.tv_sec + ts.tv_nsec * 1e-9;
}

int main(int argc, char **argv) {
	size_t n = (size_t)NX * (size_t)NY * (size_t)NZ;
	double *grid = malloc(sizeof(double) * n);
	double *newgrid = malloc(sizeof(double) * n);

	if (!grid || !newgrid) {
		fprintf(stderr, "Allocation failed\n");
		return 1;
	}

	// Deterministic initialization
	#pragma omp parallel for collapse(3)
	for (int k = 0; k < NZ; ++k)
	for (int j = 0; j < NY; ++j)
	for (int i = 0; i < NX; ++i) {
		grid[IDX(i,j,k)] = (double)i + (double)j + (double)k;
	}

	double t0 = now_sec();

	for (int step = 0; step < STEPS; ++step) {
		#pragma omp parallel for collapse(3)
		for (int k = 1; k < NZ-1; ++k) {
			for (int j = 1; j < NY-1; ++j) {
				for (int i = 1; i < NX-1; ++i) {
					double center = grid[IDX(i,j,k)];
					double xp = grid[IDX(i+1,j,k)];
					double xm = grid[IDX(i-1,j,k)];
					double yp = grid[IDX(i,j+1,k)];
					double ym = grid[IDX(i,j-1,k)];
					double zp = grid[IDX(i,j,k+1)];
					double zm = grid[IDX(i,j,k-1)];
					newgrid[IDX(i,j,k)] = (center + xp + xm + yp + ym + zp + zm) / 7.0;
				}
			}
		}
		// swap
		double *tmp = grid;
		grid = newgrid;
		newgrid = tmp;
	}

	double t1 = now_sec();
	double elapsed = t1 - t0;

	double sum = 0.0;
	#pragma omp parallel for reduction(+:sum)
	for (size_t idx = 0; idx < n; ++idx) sum += grid[idx];

	if (mkdir("results/baseline", 0755) != 0 && errno != EEXIST) {
		fprintf(stderr, "Could not create results/baseline: %s\n", strerror(errno));
	}
	FILE *f = fopen("results/baseline/output_openmp.csv", "w");
	if (f) {
		fprintf(f, "run,time_seconds,NX,NY,NZ,STEPS,threads,checksum\n");
		fprintf(f, "openmp,%0.9f,%d,%d,%d,%d,%d,%.12f\n", elapsed, NX, NY, NZ, STEPS, omp_get_max_threads(), sum);
		fclose(f);
	} else {
		fprintf(stderr, "Failed to write CSV: %s\n", strerror(errno));
	}

	printf("TIME: %0.9f\n", elapsed);

	free(grid);
	free(newgrid);
	return 0;
}