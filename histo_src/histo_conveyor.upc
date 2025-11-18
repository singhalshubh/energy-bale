#include "histo.h"
#include <papi.h>

double histo_conveyor(histo_t *data) {
    int ret;
    int64_t i, pe, col, pop_col;
    double tm;
    minavgmaxD_t stat[1];

    convey_t *conveyor = convey_new(SIZE_MAX, 0, NULL, convey_opt_SCATTER);
    if (!conveyor) { printf("ERROR: convey_new failed!\n"); return -1.0; }

    ret = convey_begin(conveyor, sizeof(int64_t), 0);
    if (ret < 0) { printf("ERROR: convey_begin failed!\n"); return -1.0; }

    lgp_barrier();

    /* --- PAPI setup and start: measure entire routine --- */
    int papi_ok = 1, eventset = PAPI_NULL;
    long long val[1] = {0};
    if (PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) papi_ok = 0;
    if (papi_ok && PAPI_create_eventset(&eventset) != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_add_named_event(eventset, "cray_pm:::PM_ENERGY:MEMORY") != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_start(eventset) != PAPI_OK) papi_ok = 0;

    /* --- Everything below is now within the energy window --- */
    tm = wall_seconds();

    i = 0UL;
    while (convey_advance(conveyor, i == data->l_num_ups)) {
        for (; i < data->l_num_ups; i++) {
            col = data->pckindx[i] >> 20;
            pe  = data->pckindx[i] & 0xfffff;
            assert(pe < THREADS);
            if (!convey_push(conveyor, &col, pe))
                break;
        }
        while (convey_pull(conveyor, &pop_col, NULL) == convey_OK) {
            assert(pop_col < data->lnum_counts);
            data->lcounts[pop_col] += 1;
        }
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

    convey_free(conveyor);

    return stat->avg;  /* same return: avg time */
}
