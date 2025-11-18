#include <shmem.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <papi.h>

static double now_sec(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec * 1e-6;
}

int main(int argc, char **argv) {
    shmem_init();
    int mype = shmem_my_pe();
    int npes = shmem_n_pes();

    if (npes != 2) {
        if (mype == 0)
            fprintf(stderr, "Error: run with exactly 2 PEs.\n");
        shmem_finalize();
        return 1;
    }

    if (argc < 2) {
        if (mype == 0)
            fprintf(stderr, "Usage: %s <size_bytes>\n", argv[0]);
        shmem_finalize();
        return 1;
    }

    size_t size = atoll(argv[1]);
    int iters = atoll(argv[2]);

    // Symmetric buffer
    unsigned char *buf = (unsigned char *) shmem_malloc(size);
    if (!buf) {
        if (mype == 0) fprintf(stderr, "shmem_malloc failed.\n");
        shmem_finalize();
        return 1;
    }

    if (mype == 1) {
        for (size_t i = 0; i < size; i++)
            buf[i] = (unsigned char)(i & 0xFF);
    }

    shmem_barrier_all();

    double t0 = 0.0, t1 = 0.0, energy = 0.0;

    int papi_ok = 1, eventset = PAPI_NULL;
    long long val[1] = {0};
    if (PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) papi_ok = 0;
    if (papi_ok && PAPI_create_eventset(&eventset) != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_add_named_event(eventset, "cray_pm:::PM_ENERGY:NODE") != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_start(eventset) != PAPI_OK) papi_ok = 0;

    if (mype == 0) {
        t0 = now_sec();
        for (int i = 0; i < iters; i++) {
            shmem_getmem(buf, buf, size, 1);
            shmem_quiet();
        }
        t1 = now_sec();
    }
    shmem_barrier_all();
    if (papi_ok && PAPI_stop(eventset, val) == PAPI_OK) {
        energy = val[0];
    }
    printf("energy=%.6f J\n", energy);
    double *energy_per_op = (double *) shmem_malloc(sizeof(double));
    *energy_per_op = 0.0;
    shmem_double_sum_to_all(energy_per_op, &energy, 1, 0, 0, shmem_n_pes(), NULL, NULL);
    if (mype == 0) {
        double avg = (t1 - t0) / iters;
        printf("size=%zu,  avg_time=%e s,  energy=%.6f J\n",
               size, avg, *energy_per_op);
    }

    shmem_free(buf);
    shmem_finalize();
    return 0;
}
