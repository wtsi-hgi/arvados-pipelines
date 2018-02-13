#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

hints:
  ResourceRequirement:
    ramMin: 4000
    coresMin: 1
    tmpdirMin: 1000

requirements:
- class: DockerRequirement
  dockerPull: mercury/java-memory-test:v2

inputs: []

outputs:
- test_output: stdout

baseCommand:
- java
- MemoryTest
