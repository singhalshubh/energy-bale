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

    if (npes < 2) {
        if (mype == 0) fprintf(stderr, "Need >= 2 PEs\n");
        shmem_finalize();
        return 1;
    }

    const int iters     = atoll(argv[1]);
    const int target_pe = 1;      // all atomics go to PE 1

    long *x = (long *) shmem_malloc(sizeof(long));
    if (!x) {
        if (mype == 0) fprintf(stderr, "shmem_malloc failed\n");
        shmem_finalize();
        return 1;
    }

    if (mype == target_pe)
        *x = 0;

    shmem_barrier_all();

    double t0 = 0.0, t1 = 0.0, energy = 0.0;

    // --- PAPI SETUP ONLY ON PE0 ---
    int papi_ok   = 1;
    int eventset  = PAPI_NULL;
    long long pm_val = 0;
    if (PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) papi_ok = 0;
    if (papi_ok && PAPI_create_eventset(&eventset) != PAPI_OK)          papi_ok = 0;
    if (papi_ok && PAPI_add_named_event(eventset, "cray_pm:::PM_ENERGY:NODE") != PAPI_OK)
        papi_ok = 0;
    if (papi_ok && PAPI_start(eventset) != PAPI_OK) papi_ok = 0;

    t0 = now_sec();

    // -------- 100 ATOMIC ADD OPERATIONS --------
    for (int i = 0; i < iters; i++) {
        if (mype != target_pe) {
            shmem_long_atomic_add(x, 1, target_pe);
            shmem_quiet();
        }
    }

    t1 = now_sec();

    shmem_barrier_all();
    if (papi_ok && PAPI_stop(eventset, &pm_val) == PAPI_OK)
        energy = (double)pm_val;
    
    double total_time     = t1 - t0;
    double *time_per_op = (double *) shmem_malloc(sizeof(double));
    *time_per_op = 0.0;
    shmem_double_max_to_all(time_per_op, &total_time, 1, 0, 0, shmem_n_pes(), NULL, NULL);
    double *energy_per_op = (double *) shmem_malloc(sizeof(double));
    *energy_per_op = 0.0;
    shmem_double_sum_to_all(energy_per_op, &energy, 1, 0, 0, shmem_n_pes(), NULL, NULL);

    if(mype == 0)
        fprintf(stderr, "atomic_add: time_per_op=%e s, total energy=%e J\n",
            *time_per_op/iters, *energy_per_op/(double)shmem_n_pes());

    shmem_free(x);
    shmem_finalize();
    return 0;
}
