/******************************************************************
//
//
//  Copyright(C) 2019-2020, Institute for Defense Analyses
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

/*! \file ig_conveyor.upc
 * \brief A conveyor implementation of indexgather.
 */
#include "ig.h"
#include <papi.h>

/*!
 * \brief This routine implements the conveyor variant of indexgather.
 * \param *tgt array of target locations for the gathered values
 * \param *pckindx array of packed indices for the distributed version of the global array of counts.
 * \param l_num_req the length of the pcindx array
 * \param *ltable localized pointer to the count array.
 * \return average run time
 *
 */
double ig_conveyor(int64_t *tgt, int64_t *pckindx, int64_t l_num_req,  int64_t *ltable) {
  double tm;
  int64_t pe, fromth, fromth2;
  int64_t i = 0, from;
  minavgmaxD_t stat[1];
  bool more;

  typedef struct pkg_t {
    int64_t idx;
    int64_t val;
  } pkg_t;
  pkg_t pkg;
  pkg_t *ptr = calloc(1, sizeof(pkg_t));
  
  convey_t* requests = convey_new(SIZE_MAX, 0, NULL, convey_opt_SCATTER);
  assert( requests != NULL );
  convey_t* replies = convey_new(SIZE_MAX, 0, NULL, 0);
  assert( replies != NULL );

  convey_begin(requests, sizeof(pkg_t), 0);
  convey_begin(replies, sizeof(pkg_t), 0);
  lgp_barrier();
  
  tm = wall_seconds();

  int papi_ok = 1, eventset = PAPI_NULL;
    long long val[1] = {0};
    if (PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) papi_ok = 0;
    if (papi_ok && PAPI_create_eventset(&eventset) != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_add_named_event(eventset, "cray_pm:::PM_ENERGY:MEMORY") != PAPI_OK) papi_ok = 0;
    if (papi_ok && PAPI_start(eventset) != PAPI_OK) papi_ok = 0;


  i = 0;
  while (more = convey_advance(requests, (i == l_num_req)),
         more | convey_advance(replies, !more)) {

    for (; i < l_num_req; i++) {
      pkg.idx = i;
      pkg.val = pckindx[i] >> 16;
      pe = pckindx[i] & 0xffff;
      if (! convey_push(requests, &pkg, pe))
        break;
    }

    while (convey_pull(requests, ptr, &from) == convey_OK) {
      pkg.idx = ptr->idx;
      pkg.val = ltable[ptr->val];
      if (! convey_push(replies, &pkg, from)) {
        convey_unpull(requests);
        break;
      }
    }

    while (convey_pull(replies, ptr, NULL) == convey_OK)
      tgt[ptr->idx] = ptr->val;
  }

  tm = wall_seconds() - tm;
  free(ptr);
  lgp_barrier();

  /* --- stop PAPI and compute total energy --- */
    double my_energy = 0.0;
    if (papi_ok && PAPI_stop(eventset, val) == PAPI_OK)
        my_energy = (double)val[0]/(1);   /* Joules */

    /* sum across all PEs */
    double total_energy = (double)lgp_reduce_add_l((int64_t)my_energy);

    if (MYTHREAD == 0)
        printf("TOTAL CPU PACKAGE ENERGY (histo_agp, full) = %.3f J across %ld PEs\n",
              total_energy/64, (long)THREADS);

  lgp_min_avg_max_d( stat, tm, THREADS );
  convey_free(requests);
  convey_free(replies);
  return( stat->avg );
}
