# CWL Workflow

Workflow.cwl takes in a dict file as an input and outputs the correct number of split interval lists by running the convert and split scripts within a docker container.

## Docker Requirement

These workflows have a dependency on docker. To install the docker container run:

```bash
docker build . -t arvados_pipeline_python
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
