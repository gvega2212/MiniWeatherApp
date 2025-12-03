# ==========================================
# miniWeather – C (serial, OpenMP, MPI+OMP, OpenACC GPU)
# ==========================================

# Compilers
CC        = mpicc
ACCCC     = nvc

# Base Flags
CFLAGS_BASE  = -O3 -Wall
OMPFLAGS     = -fopenmp

# OpenACC flags
ACCFLAGS     = -acc -gpu=cc80 -Minfo=accel -O3
ACCLDFLAGS   = -acc

# ---------------------------
# Problem size (overridable)
# ---------------------------
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
CPU_TARGETS = miniweather_serial miniweather_openmp miniweather_mpi miniweather_hybrid
GPU_TARGETS = miniweather_openacc miniweather_mpi_openacc

# Default build = CPU ONLY
all: cpu

cpu: $(CPU_TARGETS)

gpu: $(GPU_TARGETS)

# ===========================
# CPU versions
# ===========================

miniweather_serial: miniweather_serial.c
	$(CC) $(CFLAGS_CPU) -o $@ $^

miniweather_openmp: miniweather_openmp.c
	$(CC) $(CFLAGS_OMP) -o $@ $^ $(OMPFLAGS)

miniweather_mpi: miniweather_mpi.c
	$(CC) $(CFLAGS_OMP) -o $@ $^ $(OMPFLAGS)

miniweather_hybrid: miniweather_hybrid.c
	$(CC) $(CFLAGS_OMP) -o $@ $^ $(OMPFLAGS)

# ===========================
# GPU versions (OpenACC)
# ===========================

miniweather_openacc: miniweather_openacc.c
	$(ACCCC) $(ACCFLAGS) -o $@ $^ $(ACCLDFLAGS)

miniweather_mpi_openacc: miniweather_mpi_openacc.c
	$(ACCCC) $(ACCFLAGS) -o $@ $^ $(ACCLDFLAGS)

# ===========================
# Cleaning
# ===========================

clean:
	rm -f $(CPU_TARGETS) $(GPU_TARGETS) *.o

# ===========================
# Convenience run targets
# ===========================

N ?= 4

run_serial: miniweather_serial
	./miniweather_serial

run_openmp: miniweather_openmp
	./miniweather_openmp

run_mpi_local: miniweather_mpi
	@mkdir -p ../results
	mpirun -np $(N) ./miniweather_mpi | tee ../results/mpi_$(N)ranks_local.txt

run_gpu: miniweather_openacc
	@mkdir -p ../results
	./miniweather_openacc | tee ../results/gpu_openacc_local.txt

run_multigpu_local: miniweather_mpi_openacc
	@mkdir -p ../results
	mpirun -np $(N) ./miniweather_mpi_openacc | tee ../results/multigpu_$(N)gpus_local.txt

# ===========================
# Metrics
# ===========================

metrics_local:
	@cd ../results && \
	echo "ranks,time_seconds" > scaling_local.csv && \
	for f in `ls mpi_*rank*_local.txt 2>/dev/null | sort -V`; do \
	  r=`echo $$f | sed -E 's/.*mpi_([0-9]+)rank.*/\1/'`; \
	  t=`grep -oE 'TIME=([0-9.]*)' $$f | cut -d= -f2`; \
	  echo "$$r,$$t" >> scaling_local.csv; \
	done

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
	done

.PHONY: all cpu gpu clean
