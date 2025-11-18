# ============================================================
# Minimal Makefile for SHMEM + PAPI microbenchmarks
# ============================================================

CC      = cc
CFLAGS  = -O3 -std=c++17
LIBS    = -lpapi

SRC     = atomic_add.cpp fetch_add.cpp fetch_inc.cpp put.cpp get.cpp
TARGETS = $(SRC:.cpp=)

all: $(TARGETS)

%: %.cpp
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

clean:
	rm -f $(TARGETS)
