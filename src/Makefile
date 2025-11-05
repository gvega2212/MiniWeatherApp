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
    # Windows with Microsoft MPI
    CC = mpicxx
    CFLAGS = -I"C:/Program Files (x86)/Microsoft SDKs/MPI/Include" -O2
    LDFLAGS = -L"C:/Program Files (x86)/Microsoft SDKs/MPI/Lib/x64"
else
    # Linux / Cluster
    CC = mpicxx
    CFLAGS = -O2 -std=c++17
    LDFLAGS =
endif

# --------------------------
# Targets
# --------------------------
TARGET = miniweather_mpi
SRC = main.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)
