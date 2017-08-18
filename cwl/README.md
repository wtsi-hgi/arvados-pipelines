# CWL Workflow

Workflow.cwl takes in a dict file as an input and outputs the correct number of split interval lists by running the convert and split scripts within a docker container.

## Cloning

Clone this with the included submodule:

```bash
git clone --recursive https://github.com/wtsi-hgi/arvados-pipelines.git
```

## Docker Requirement

These workflows have a dependencies on docker containers. To install the docker containers run:

```bash
docker build dict_to_interval_list -t dict_to_interval_list
docker build split_interval_list -t split_interval_list
docker build intersect_intervals -t intersect_intervals
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
