#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re

from hgi import errors

def _execute(gatk_args, *args, gatk_jar="/gatk/GenomeAnalysisTK.jar", java_mem="1g", print_first_n_lines=300, print_lines_matching_regex=r'(FATAL|ERROR|ProgressMeter)', output_prefix="GATK: ", **kwargs):
    print "Calling %s%s" % (output_prefix, gatk_args)
    java_args = [
            "java", "-d64", "-Xmx%s" % (java_mem)
    ]
    if extra_java_args:
        java_args.extend(extra_java_args)
    java_args.extend(["-jar", gatk_jar])
    java_args.extend(gatk_args)
    if extra_gatk_args:
        java_args.extend(extra_gatk_args)
    gatk_p = subprocess.Popen(
        java_args,
        stdin=None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        close_fds=True,
        shell=False)

    gatk_line_num = 0
    while gatk_p.poll() is None:
        line = gatk_p.stdout.readline()
        gatk_line_num += 1
        if gatk_line_num <= print_first_n_lines:
            print "%s%s" % (output_prefix, line.rstrip())
        elif re.search(print_lines_matching_regex, line):
            print "%s%s" % (output_prefix, line.rstrip())

    gatk_exit = gatk_p.wait()
   return gatk_exit


def combine_gvcfs(ref_file, gvcf_files, out_path, *args, java_mem="5g", **kwargs):
    print "combine_gvcfs called with ref_file=[%s] gvcf_files=[%s] out_path=[%s] *args=[%s] java_mem=[%s] **kwargs=[%s]" % (ref_file, ' '.join(gvcf_files), out_path, ' '.join(*args), java_mem, ' '.join(**kwargs))
    # Call GATK CombineGVCFs
    gatk_args = [
            "-T", "CombineGVCFs",
            "-R", ref_file]
    for gvcf_file in gvcf_files:
        gatk_args.extend(["--variant", gvcf_file])
    gatk_args.extend([
        "-o", out_path
    ])
    return _execute(gatk_args, *args, java_mem=java_mem, **kwargs)


def haplotype_caller(ref_file, cram_file, interval_list_file, out_path, *args, java_mem="20g", **kwargs):
    print "haplotype_caller called with ref_file=[%s] cram_file=[%s] interval_list_file=[%s] out_path=[%s], *args=[%s] java_mem=[%s] **kwargs=[%s]" % (ref_file, cram_file, interval_list_file, out_file, ' '.join(*args), java_mem, ' '.join(**kwargs))
    # Call GATK HaplotypeCaller
    gatk_args = [
        "-T", "HaplotypeCaller",
        "-R", ref_file,
        "-I", cram_file,
        "-L", interval_list_file,
        "-nct", "4",
        "--emitRefConfidence", "GVCF",
        "--variant_index_type", "LINEAR",
        "--variant_index_parameter", "128000",
        "-o", out_path,
        "-l", "INFO"
        ]
    return _execute(gatk_args, *args, java_mem=java_mem, **kwargs)
