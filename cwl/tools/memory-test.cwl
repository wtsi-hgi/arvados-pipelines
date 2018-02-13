#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

requirements:
- class: DockerRequirement
  dockerPull: mercury/java-memory-test:v1

inputs: []

outputs:
  test_output: stdout

baseCommand:
- java
- MemoryTest
