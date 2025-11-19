## Benchmarking Energy Consumption
- Profile weak scaling experiment for four applications - Triangle Counting, Index Gather, Histogram and Topological Sort.

- The energy counter `cray_pm:::PM_ENERGY:MEMORY` and `cray_pm:::PM_ENERGY:NODE` is used for instrumentation for all four application codes in AGP and Conveyors version. Thye both measure the energy drawn in joules. This code repository consists of `memory`, and one should replace it with `node` accordingly. 

- The aim of this experiment is to understand whether the program is power hungry or not? In addition, we also measure why AGP takes more energy, attributing to scaling laws of energy for OpenSHMEM APIs. Find the benchmark studies for APIs in `scaling-energy-benchmark`.

## Directory Structure

Refer to [bale](https://github.com/jdevinney/bale) for full repository. This repository only contains the energy instrumentation for chosen applications.

```
.
├── histo_src
│   ├── histo_agp.upc
│   ├── histo_conveyor.upc
│   ├── histo.h
│   └── histo.upc
├── ig_src
│   ├── ig_agp.upc
│   ├── ig_conveyor.upc
│   ├── ig.h
│   └── ig.upc
├── README.md
├── scaling-energy-benchmark
│   ├── atomic_add.cpp
│   ├── fetch_add.cpp
│   ├── fetch_inc.cpp
│   ├── get.cpp
│   ├── Makefile
│   ├── put.cpp
│   └── run.sh
├── topo_src
│   ├── toposort_agp.upc
│   ├── toposort_conveyor.upc
│   ├── toposort.h
│   └── toposort.upc
└── triangle_src
    ├── triangle_agp.upc
    ├── triangle_conveyor.upc
    ├── triangle.h
    └── triangle.upc

5 directories, 24 files
```

## Conclusions
Please find the presentation attached for more information: [Link](https://docs.google.com/presentation/d/1S2U0r-D9DZmml_K5_AKurb_52aJ2zLlDU-tQJF5r4wg/edit?usp=sharing)