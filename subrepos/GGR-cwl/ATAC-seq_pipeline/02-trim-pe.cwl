#!/usr/bin/env cwl-runner
cwlVersion: "cwl:draft-3"
class: Workflow
description: "ATAC-seq 02 trimming - reads: PE"
requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
inputs:
  - id: "#input_read1_fastq_files"
    type:
      type: array
      items: File
    description: "Input read 1 fastq files"
  - id: "#input_read2_fastq_files"
    type:
      type: array
      items: File
    description: "Input read 2 fastq files"
  - id: "#input_read1_adapters_files"
    type:
      type: array
      items: File
    description: "Input read 1 adapters files"
  - id: "#input_read2_adapters_files"
    type:
      type: array
      items: File
    description: "Input read 2 adapters files"
  - id: "#nthreads"
    type: int
    default: 1
    description: "Number of threads"
  - id: "#quality_score"
    type: string
    default: "-phred33"
  - id: "#trimmomatic_jar_path"
    type: string
    default: "/usr/share/java/trimmomatic.jar"
    description: "Trimmomatic Java jar file"
  - id: "#trimmomatic_java_opts"
    type:
      - 'null'
      - string
    description: "JVM arguments should be a quoted, space separated list"
outputs:
  - id: "#output_data_fastq_read1_trimmed_files"
    source: "#trimmomatic.output_read1_trimmed_file"
    description: "Trimmed fastq files for paired read 1"
    type:
      type: array
      items: File
  - id: "#output_data_fastq_read2_trimmed_files"
    source: "#trimmomatic.output_read2_trimmed_paired_file"
    description: "Trimmed fastq files for paired read 2"
    type:
      type: array
      items: File
  - id: "#output_trimmed_read1_fastq_read_count"
    source: "#count_fastq_reads_read1.output_read_count"
    description: "Trimmed read counts of paired read 1 fastq files"
    type:
      type: array
      items: File
  - id: "#output_trimmed_read2_fastq_read_count"
    source: "#count_fastq_reads_read2.output_read_count"
    description: "Trimmed read counts of paired read 2 fastq files"
    type:
      type: array
      items: File
steps:
  - id: "#concat_adapters"
    run: {$import: "../utils/concat-files.cwl"}
    scatter:
      - "#concat_adapters.input_file1"
      - "#concat_adapters.input_file2"
    scatterMethod: dotproduct
    inputs:
      - id: "#concat_adapters.input_file1"
        source: "#input_read1_adapters_files"
      - id: "#concat_adapters.input_file2"
        source: "#input_read2_adapters_files"
    outputs:
      - id: "#concat_adapters.output_file"
  - id: "#trimmomatic"
    run: {$import: "../trimmomatic/trimmomatic.cwl"}
    scatter:
      - "#trimmomatic.input_read1_fastq_file"
      - "#trimmomatic.input_read2_fastq_file"
      - "#trimmomatic.input_adapters_file"
    scatterMethod: dotproduct
    inputs:
      - id: "#trimmomatic.input_read1_fastq_file"
        source: "#input_read1_fastq_files"
      - id: "#trimmomatic.input_read2_fastq_file"
        source: "#input_read2_fastq_files"
      - id: "#trimmomatic.input_adapters_file"
        source: "#concat_adapters.output_file"
      - id: "#trimmomatic.nthreads"
        source: "#nthreads"
      - id: "#trimmomatic.java_opts"
        source: "#trimmomatic_java_opts"
      - id: "#trimmomatic.trimmomatic_jar_path"
        source: "#trimmomatic_jar_path"
      - id: "#trimmomatic.illuminaclip"
        valueFrom: "2:30:15"
      - id: "#trimmomatic.end_mode"
        valueFrom: "PE"
      - id: "#trimmomatic.leading"
        valueFrom: $(3)
      - id: "#trimmomatic.trailing"
        valueFrom: $(3)
      - id: "#trimmomatic.slidingwindow"
        valueFrom: "4:20"
      - id: "#trimmomatic.minlen"
        valueFrom: $(15)
      - id: "#trimmomatic.phred"
        valueFrom: "33"
    outputs:
      - id: "#trimmomatic.output_read1_trimmed_file"
#      - id: "#trimmomatic.output_read1_trimmed_unpaired_file"
      - id: "#trimmomatic.output_read2_trimmed_paired_file"
#      - id: "#trimmomatic.output_read2_trimmed_unpaired_file"
  - id: "#extract_basename_read1"
    run: {$import: "../utils/extract-basename.cwl" }
    scatter: "#extract_basename_read1.input_file"
    inputs:
      - id: "#extract_basename_read1.input_file"
        source: "#trimmomatic.output_read1_trimmed_file"
    outputs:
      - id: "#extract_basename_read1.output_basename"
  - id: "#extract_basename_read2"
    run: {$import: "../utils/extract-basename.cwl" }
    scatter: "#extract_basename_read2.input_file"
    inputs:
      - id: "#extract_basename_read2.input_file"
        source: "#trimmomatic.output_read2_trimmed_paired_file"
    outputs:
      - id: "#extract_basename_read2.output_basename"
  - id: "#count_fastq_reads_read1"
    run: {$import: "../utils/count-fastq-reads.cwl" }
    scatter:
      - "#count_fastq_reads_read1.input_fastq_file"
      - "#count_fastq_reads_read1.input_basename"
    scatterMethod: dotproduct
    inputs:
      - id: "#count_fastq_reads_read1.input_fastq_file"
        source: "#trimmomatic.output_read1_trimmed_file"
      - id: "#count_fastq_reads_read1.input_basename"
        source: "#extract_basename_read1.output_basename"
    outputs:
      - id: "#count_fastq_reads_read1.output_read_count"
  - id: "#count_fastq_reads_read2"
    run: {$import: "../utils/count-fastq-reads.cwl" }
    scatter:
      - "#count_fastq_reads_read2.input_fastq_file"
      - "#count_fastq_reads_read2.input_basename"
    scatterMethod: dotproduct
    inputs:
      - id: "#count_fastq_reads_read2.input_fastq_file"
        source: "#trimmomatic.output_read2_trimmed_paired_file"
      - id: "#count_fastq_reads_read2.input_basename"
        source: "#extract_basename_read2.output_basename"
    outputs:
      - id: "#count_fastq_reads_read2.output_read_count"