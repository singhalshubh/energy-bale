/******************************************************************
//
//
//  Copyright(C) 2020, Institute for Defense Analyses
//  4850 Mark Center Drive, Alexandria, VA; 703-845-2500
// 
//
//  All rights reserved.
//  
//   This file is a part of Bale.  For license information see the
//   LICENSE file in the top level directory of the distribution.
//  
// 
 *****************************************************************/ 

/*! \file ig_agp.upc
 * \brief The intuitive implementation of indexgather that uses single word gets to shared addresses.
 */
#include "ig.h"
#include <papi.h>

/*!
 * \brief This routine implements the single word get version indexgather
 * \param *tgt array of target locations for the gathered values
 * \param *index array of indices into the global array of counts
 * \param l_num_req the length of the index array
 * \param *table shared pointer to the shared table array.
 * \return average run time
 *
 */
double ig_agp(int64_t *tgt, int64_t *index, int64_t l_num_req,  SHARED int64_t *table) {
  int64_t i;
  double tm;
  minavgmaxD_t stat[1];

  lgp_barrier();
  tm = wall_seconds();

  int papi_ok = 1, eventset = PAPI_NULL;
    long long val[1] = {0};
    if (PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) papi_ok = 0;
    if (papi_ok && PAPI_create_eventset(&eventset) != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_add_named_event(eventset, "cray_pm:::PM_ENERGY:MEMORY") != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_start(eventset) != PAPI_OK) papi_ok = 0;

  for(i = 0; i < l_num_req; i++){
    #if __cray__ || _CRAYC
    #pragma pgas defer_sync
    #endif
    tgt[i] = lgp_get_int64(table, index[i]);
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

  lgp_min_avg_max_d( stat, tm, THREADS );

  return( stat->avg );
}

