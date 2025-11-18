#!/bin/bash
MAX=128

for (( NODES=1; NODES<=MAX; NODES*=2 ))
do
    srun -N ${NODES} -n $((64 * $NODES)) ./atomic_add
done

for (( NODES=1; NODES<=MAX; NODES*=2 ))
do
    srun -N ${NODES} -n $((64 * $NODES)) ./fetch_add
done

for (( NODES=1; NODES<=MAX; NODES*=2 ))
do
    srun -N ${NODES} -n $((64 * $NODES)) ./fetch_inc
done


