# ==========================================
# miniWeather – C (serial, OpenMP, MPI+OMP, OpenACC GPU)
# ==========================================

# Compilers
CC      = mpicc
ACCCC   = nvc     # NVIDIA HPC Compiler for OpenACC (only used if GPU builds requested)

# Flags
CFLAGS   = -O3 -Wall -fopenmp
LDFLAGS  = -fopenmp

# OpenACC flags (only used if GPU build is invoked)
ACCFLAGS    = -acc -gpu=cc80 -Minfo=accel -O3
ACCLDFLAGS  = -acc -lmpi

# ---------------------------
# Problem size (override)
# ---------------------------
NX    ?= 256
NY    ?= 128
NZ    ?= 128
STEPS ?= 50

DEFS = -DNX=$(NX) -DNY=$(NY) -DNZ=$(NZ) -DSTEPS=$(STEPS)

CFLAGS   += $(DEFS)
ACCFLAGS += $(DEFS)

# ---------------------------
# CPU-only targets (default)
# ---------------------------
CPU_TARGETS = \
    miniweather_serial \
    miniweather_openmp \
    miniweather_mpi \
    miniweather_hybrid

# GPU-only (must be requested manually)
GPU_TARGETS = \
    miniweather_openacc \
    miniweather_mpi_openacc

# Default: CPU-only
all: $(CPU_TARGETS)

# --------------------------------
# CPU builds
# --------------------------------
miniweather_serial: miniweather_serial.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

miniweather_openmp: miniweather_openmp.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

miniweather_mpi: miniweather_mpi.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

miniweather_hybrid: miniweather_hybrid.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# --------------------------------
# GPU builds (only built if user explicitly runs: make miniweather_openacc)
# --------------------------------
miniweather_openacc: miniweather_openacc.c
	$(ACCCC) $(ACCFLAGS) -o $@ $^ $(ACCLDFLAGS)

miniweather_mpi_openacc: miniweather_mpi_openacc.c
	$(ACCCC) $(ACCFLAGS) -o $@ $^ $(ACCLDFLAGS)

# --------------------------------
# Cleaning
# --------------------------------
clean:
	rm -f $(CPU_TARGETS) $(GPU_TARGETS) *.o

.PHONY: all clean
