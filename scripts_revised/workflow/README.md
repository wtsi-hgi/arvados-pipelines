# CWL Workflow

Workflow.cwl takes in a dict file as an input and outputs the correct number of split interval lists by running the convert and split scripts within a docker container.

## Docker Requirement

The cwl file has a dependency on docker. First, build the two docker containers in this folder by running:

```docker build convert_docker/ -t convert```

and

```docker build split_docker/ -t split```

## Usage

To run the CWL file, run:

```cwl_runner --outdir /path/to/output workflow.cwl inputs.yml```

and specifying the necessary output directory.

Within the inputs.yml file, specify the three inputs necessary for the script using the following template:

```
genome_chunks: 200
dict:
  class: File
  path: /path/to/dict/file
```