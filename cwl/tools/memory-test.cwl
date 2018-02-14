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

inputs:
 - id: input
   type: string

stdout: output.txt

outputs:
 - id: output
   type: File
   outputBinding:
     glob: output.txt

baseCommand:
- java
- -XX:+UnlockExperimentalVMOptions
- -XX:+UseCGroupMemoryLimitForHeap
- MemoryTest
