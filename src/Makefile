# ==========================================
# miniWeather – C (serial, OpenMP, MPI+OMP)
# ==========================================

# MPI C compiler
CC      = mpicc
CFLAGS  = -O3 -Wall -fopenmp
LDFLAGS = -fopenmp

# ---------------------------
# Problem size (overridable)
# ---------------------------
# You can override these on the command line, e.g.:
#   make miniweather_mpi NX=512 NY=256 NZ=256 STEPS=100
NX     ?= 256
NY     ?= 128
NZ     ?= 128
STEPS  ?= 50

DEFS = -DNX=$(NX) -DNY=$(NY) -DNZ=$(NZ) -DSTEPS=$(STEPS)
CFLAGS += $(DEFS)

# ---------------------------
# Targets
# ---------------------------
TARGETS = miniweather_serial miniweather_openmp miniweather_mpi

all: $(TARGETS)

miniweather_serial: miniweather_serial.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

miniweather_openmp: miniweather_openmp.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

miniweather_mpi: miniweather_mpi.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

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
	@echo "Running $(N) ranks → ../results/mpi_$(N)ranks_local.txt"
	mpirun -np $(N) ./miniweather_mpi | tee ../results/mpi_$(N)ranks_local.txt

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