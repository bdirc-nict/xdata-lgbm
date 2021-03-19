README
------

The repository contains Greenplum UDF wrapper for Ox-level prediction by LightGBM.

## Directory structure

```
/
|-- benchmarks     Client scripts, which uses provenance API
`-- src
    |-- lgbm       GPU server side stub scripts
    |-- lgbm-stub  Database server side stub scripts
    `-- lgbm-udf   Greenplum UDFs
```

## Benchmarking

- Confirm you have setup Ox-level prediction module and the provenance environment correctory
- Execute benchmark program as follows:
```
$ python benchmarks/benchmark.py
```
