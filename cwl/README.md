# CWL Workflow

CWL workflow files for part of the pipeline

## Prerequisites
- python 2

## Cloning

Clone this with the included submodule (to get the bedtools intersect CWL file):

```bash
git clone --recursive https://github.com/wtsi-hgi/arvados-pipelines.git
```

## Installation

These workflows have a dependencies on docker containers. To install the docker containers run:

```bash
docker build -t dict_to_interval_list tools/dict_to_interval_list
docker build -t split_interval_list tools/split_interval_list
docker build -t intersect_intervals tools/intersect_intervals
```

## Usage

To run the CWL file, run:

```bash
cwl-runner --outdir /path/to/output workflow.cwl inputs.yml
```

and specifying the necessary output directory.

Within the inputs.yml file, specify the three inputs necessary for the script using the following template:

```bash
genome_chunks: 200
dict:
  class: File
  path: /path/to/dict/file
```

## Tests

To run the tests, run:
```bash
pip install -r test_requirements.txt

pytest -s tests/test.py
```
Depending on the size of the test data and the hardware, the tests can take a while to run; for example, full chromosome 22 data takes 11 minutes to complete.  The `-s` in the pytest command gives realtime output.
