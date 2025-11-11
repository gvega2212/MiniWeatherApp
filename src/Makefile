# =====================================
# miniWeather Makefile (Cross-Platform)
# =====================================

# Detect OS type
UNAME_S := $(shell uname -s)

# --------------------------
# Compiler & include settings
# --------------------------
ifeq ($(UNAME_S),Darwin)
    # macOS
    ifneq (,$(wildcard /opt/homebrew))
        MPI_HOME = /opt/homebrew/opt/open-mpi
    else
        MPI_HOME = /usr/local/opt/open-mpi
    endif
    CC = $(MPI_HOME)/bin/mpicxx
    CFLAGS = -I$(MPI_HOME)/include -O2 -std=c++17
    LDFLAGS = -L$(MPI_HOME)/lib
else ifeq ($(OS),Windows_NT)
    CC = mpicxx
    CFLAGS = -I"C:/Program Files (x86)/Microsoft SDKs/MPI/Include" -O2
    LDFLAGS = -L"C:/Program Files (x86)/Microsoft SDKs/MPI/Lib/x64"
else
    CC = mpicxx
    CFLAGS = -O2 -std=c++17
    LDFLAGS =
endif


TARGET = miniweather_mpi
SRC = main.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)


NX ?= 256
NY ?= 128
NZ ?= 128
STEPS ?= 50

CDEFS := -DNX=$(NX) -DNY=$(NY) -DNZ=$(NZ) -DSTEPS=$(STEPS)

CFLAGS += $(CDEFS)

N ?= 4
run: $(TARGET)
	@echo "Running $(N) ranks → results/mpi_$(N)ranks_local.txt"
	mpirun --bind-to core --map-by core -np $(N) ./$(TARGET) | tee ../results/mpi_$(N)ranks_local.txt

metrics:
	@cd ../results && \
	echo "ranks,time_seconds" > scaling_local.csv && \
	for f in `ls mpi_*rank*_local.txt 2>/dev/null | sort -V`; do \
	  r=`echo $$f | sed -E 's/.*mpi_([0-9]+)rank.*/\1/'`; \
	  t=`grep -oE 'TIME=([0-9.]*)' $$f | cut -d= -f2`; \
	  echo "$$r,$$t" >> scaling_local.csv; \
	done && \
	awk -F, 'NR==1{print "ranks,time_seconds,speedup,efficiency_pct"; next} NR==2{t1=$$2} NR>1{speed=t1/$$2; eff=100*speed/$$1; printf "%s,%.6f,%.4f,%.1f\n",$$1,$$2,speed,eff}' scaling_local.csv > scaling_local_metrics.csv && \
	echo "Wrote results/scaling_local.csv and results/scaling_local_metrics.csv"

