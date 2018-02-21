#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

hints:
  ResourceRequirement:
    ramMin: 100
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
 - bash
 - "-c"
 - "java -XX:MaxRAMFraction=1 -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap MemoryTest && echo -n \"limit_in_bytes for cgroup: \" && cat /sys/fs/cgroup/memory/memory.limit_in_bytes"
