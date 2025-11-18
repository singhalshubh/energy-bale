#include "histo.h"
#include <papi.h>

double histo_agp(histo_t *data) {
    double tm;
    int64_t i;
    minavgmaxD_t stat[1];

    /* --- PAPI setup and start (measure entire routine) --- */
    int papi_ok = 1, eventset = PAPI_NULL;
    long long val[1] = {0};
    if (PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) papi_ok = 0;
    if (papi_ok && PAPI_create_eventset(&eventset) != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_add_named_event(eventset, "cray_pm:::PM_ENERGY:MEMORY") != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_start(eventset) != PAPI_OK) papi_ok = 0;

    /* --- everything below included in energy window --- */
    lgp_barrier();
    tm = wall_seconds();

    for (i = 0; i < data->l_num_ups; i++) {
    #if __cray__ || _CRAYC
        #pragma pgas defer_sync
    #endif
        assert(data->index[i] < data->num_counts);
        lgp_atomic_add(data->counts, data->index[i], 1L);
    }

    lgp_barrier();

    /* --- stop PAPI and compute total energy --- */
    double my_energy = 0.0;
    if (papi_ok && PAPI_stop(eventset, val) == PAPI_OK)
        my_energy = (double)val[0]/(double)(1);   /* Joules */

    /* sum across all PEs */
    double total_energy = (double)lgp_reduce_add_l((int64_t)my_energy);

    if (MYTHREAD == 0)
        printf("TOTAL CPU PACKAGE ENERGY (histo_agp, full) = %.3f J across %ld PEs\n",
              total_energy/64, (long)THREADS);

    tm = wall_seconds() - tm;
    lgp_min_avg_max_d(stat, tm, THREADS);
    return stat->avg;  /* keep same return: avg time */
}
