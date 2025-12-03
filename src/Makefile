# ==========================================
# miniWeather – C (serial, OpenMP, MPI+OMP, OpenACC GPU)
# ==========================================

# Compilers
CC        = mpicc        # used for CPU builds (serial/OpenMP/MPI/hybrid)
ACCCC     = nvc          # NVIDIA HPC compiler for OpenACC (or pgcc/nvc++)

# Base Flags
CFLAGS_BASE  = -O3 -Wall
OMPFLAGS     = -fopenmp

# OpenACC flags (adjust -gpu=cc80 based on GPU: cc70=V100, cc80=A100, cc86=A6000)
ACCFLAGS     = -acc -gpu=cc80 -Minfo=accel -O3
ACCLDFLAGS   = -acc

# ---------------------------
# Problem size (overridable)
# ---------------------------
# You can override these on the command line, e.g.:
#   make miniweather_mpi NX=512 NY=256 NZ=256 STEPS=100
NX     ?= 256
NY     ?= 128
NZ     ?= 128
STEPS  ?= 50

DEFS       = -DNX=$(NX) -DNY=$(NY) -DNZ=$(NZ) -DSTEPS=$(STEPS)
CFLAGS_CPU = $(CFLAGS_BASE) $(DEFS)
CFLAGS_OMP = $(CFLAGS_BASE) $(OMPFLAGS) $(DEFS)
ACCFLAGS  += $(DEFS)

# ---------------------------
# Targets
# ---------------------------
TARGETS = miniweather_serial miniweather_openmp miniweather_mpi miniweather_hybrid \
          miniweather_openacc miniweather_mpi_openacc

all: $(TARGETS)

# ===========================
# CPU versions
# ===========================

# Pure serial baseline (no OpenMP)
miniweather_serial: miniweather_serial.c
	$(CC) $(CFLAGS_CPU) -o $@ $^

# OpenMP shared-memory
miniweather_openmp: miniweather_openmp.c
	$(CC) $(CFLAGS_OMP) -o $@ $^ $(OMPFLAGS)

# Pure MPI distributed-memory
miniweather_mpi: miniweather_mpi.c
	$(CC) $(CFLAGS_OMP) -o $@ $^ $(OMPFLAGS)

# Hybrid MPI + OpenMP
miniweather_hybrid: miniweather_hybrid.c
	$(CC) $(CFLAGS_OMP) -o $@ $^ $(OMPFLAGS)

# ===========================
# GPU versions (OpenACC)
# ===========================

# Single-GPU OpenACC version
miniweather_openacc: miniweather_openacc.c
	$(ACCCC) $(ACCFLAGS) -o $@ $^ $(ACCLDFLAGS)

# MPI + OpenACC (multi-GPU: one GPU per rank)
# Assumes `mpicc` is configured to use NVHPC as backend when modules are loaded.
miniweather_mpi_openacc: miniweather_mpi_openacc.c
	$(CC) $(ACCFLAGS) -o $@ $^ $(ACCLDFLAGS)

# ===========================
# Cleaning
# ===========================

clean:
	rm -f $(TARGETS) *.o

# ===========================
# Convenience run targets
# ===========================

# Number of MPI ranks for local tests (not Slurm)
N ?= 4

run_serial: miniweather_serial
	./miniweather_serial

run_openmp: miniweather_openmp
	./miniweather_openmp

run_mpi_local: miniweather_mpi
	@mkdir -p ../results
	@echo "Running $(N) ranks → ../results/mpi_$(N)ranks_local.txt"
	mpirun -np $(N) ./miniweather_mpi | tee ../results/mpi_$(N)ranks_local.txt

# GPU runs
run_gpu: miniweather_openacc
	@mkdir -p ../results
	@echo "Running single GPU → ../results/gpu_openacc_local.txt"
	./miniweather_openacc | tee ../results/gpu_openacc_local.txt

run_multigpu_local: miniweather_mpi_openacc
	@mkdir -p ../results
	@echo "Running $(N) GPUs (MPI ranks) → ../results/multigpu_$(N)gpus_local.txt"
	mpirun -np $(N) ./miniweather_mpi_openacc | tee ../results/multigpu_$(N)gpus_local.txt

# ===========================
# Metrics builders
# ===========================

# Build simple local scaling CSV from the mpi_*_local.txt logs
metrics_local:
	@cd ../results && \
	echo "ranks,time_seconds" > scaling_local.csv && \
	for f in `ls mpi_*rank*_local.txt 2>/dev/null | sort -V`; do \
	  r=`echo $$f | sed -E 's/.*mpi_([0-9]+)rank.*/\1/'`; \
	  t=`grep -oE 'TIME=([0-9.]*)' $$f | cut -d= -f2`; \
	  echo "$$r,$$t" >> scaling_local.csv; \
	done && \
	awk -F, 'NR==1{print "ranks,time_seconds,speedup,efficiency_pct"; next} NR==2{t1=$$2} NR>1{speed=t1/$$2; eff=100*speed/$$1; printf "%s,%.6f,%.4f,%.1f\n",$$1,$$2,speed,eff}' scaling_local.csv > scaling_local_metrics.csv && \
	echo "Wrote results/scaling_local.csv and results/scaling_local_metrics.csv"

# GPU scaling metrics
metrics_gpu:
	@cd ../results && \
	echo "gpus,time_seconds" > scaling_gpu.csv && \
	for f in `ls multigpu_*gpus_local.txt gpu_openacc_local.txt 2>/dev/null | sort -V`; do \
	  if echo $$f | grep -q "multigpu"; then \
	    g=`echo $$f | sed -E 's/.*multigpu_([0-9]+)gpus.*/\1/'`; \
	  else \
	    g=1; \
	  fi; \
	  t=`grep -oE 'TIME=([0-9.]*)' $$f | cut -d= -f2`; \
	  echo "$$g,$$t" >> scaling_gpu.csv; \
	done && \
	awk -F, 'NR==1{print "gpus,time_seconds,speedup,efficiency_pct"; next} NR==2{t1=$$2} NR>1{speed=t1/$$2; eff=100*speed/$$1; printf "%s,%.6f,%.4f,%.1f\n",$$1,$$2,speed,eff}' scaling_gpu.csv > scaling_gpu_metrics.csv && \
	echo "Wrote results/scaling_gpu.csv and results/scaling_gpu_metrics.csv"

.PHONY: all clean run_serial run_openmp run_mpi_local run_gpu run_multigpu_local metrics_local metrics_gpu