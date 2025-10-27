## Benchmarking Energy Consumption
- Profile weak scaling experiment for four applications - Triangle Counting, Index Gather, Histogram and Topological Sort.

- The energy counter `cray_rapl:::PACKAGE_ENERGY` is used for instrumentation for all four application codes in AGP and Conveyors version.

- The aim of this experiment is to understand whether the program is power hungry or not?

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
├── LICENSE
├── README.md
├── topo_src
│   ├── README.md
│   ├── toposort_agp.upc
│   ├── toposort_conveyor.upc
│   ├── toposort.h
│   └── toposort.upc
└── triangle_src
    ├── triangle_agp.upc
    ├── triangle_conveyor.upc
    ├── triangle.h
    └── triangle.upc

4 directories, 19 files
```

## Conclusions
Please find the presentation attached for more information: [Link](https://docs.google.com/presentation/d/1S2U0r-D9DZmml_K5_AKurb_52aJ2zLlDU-tQJF5r4wg/edit?usp=sharing)