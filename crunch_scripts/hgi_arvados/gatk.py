#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess

from hgi_arvados import errors

def _execute(gatk_args, **kwargs):
    gatk_jar = kwargs.pop("gatk_jar", "/gatk/GenomeAnalysisTK.jar")
    java_mem = kwargs.pop("java_mem", "1g")
    print_first_n_lines = kwargs.pop("print_first_n_lines", 300)
    print_lines_matching_regex = kwargs.pop("print_lines_matching_regex", "(FATAL|ERROR|ProgressMeter)")
    output_prefix = kwargs.pop("output_prefix", "GATK: ")
    extra_java_args = kwargs.pop("extra_java_args", None)
    extra_gatk_args = kwargs.pop("extra_gatk_args", None)
    if len(kwargs) > 0:
        print "Extraneous keyword arguments passed to _execute: %s" %(kwargs)
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


def combine_gvcfs(ref_file, gvcf_files, interval_list_file, out_path, **kwargs):
    java_mem = kwargs.pop("java_mem", "10g")
    print "combine_gvcfs called with ref_file=[%s] gvcf_files=[%s] out_path=[%s] java_mem=[%s] **kwargs=[%s]" % (ref_file, ' '.join(gvcf_files), out_path, java_mem, ' '.join(['%s = %s' % (k,v) for k,v in kwargs.items()]))
    # Call GATK CombineGVCFs
    gatk_args = [
            "-T", "CombineGVCFs",
            "--no_cmdline_in_header",
            "-R", ref_file,
            "-L", interval_list_file]
    for gvcf_file in gvcf_files:
        gatk_args.extend(["--variant", gvcf_file])
    gatk_args.extend([
        "-o", out_path
    ])
    return _execute(gatk_args, java_mem=java_mem, **kwargs)


def haplotype_caller(ref_file, cram_file, interval_list_file, out_path, **kwargs):
    java_mem = kwargs.pop("java_mem", "8500m")
    ploidy = kwargs.pop("ploidy", 2)
    print "haplotype_caller called with ref_file=[%s] cram_file=[%s] interval_list_file=[%s] out_path=[%s] java_mem=[%s] **kwargs=[%s]" % (ref_file, cram_file, interval_list_file, out_path, java_mem, ' '.join(['%s = %s' % (k,v) for k,v in kwargs.items()]))
    # Call GATK HaplotypeCaller
    gatk_args = [
        "-T", "HaplotypeCaller",
        "--no_cmdline_in_header",
        "-R", ref_file,
        "-I", cram_file,
        "-L", interval_list_file,
        "-A", "StrandAlleleCountsBySample",
        "-A", "StrandBiasBySample",
        "-nct", "1",
        "--emitRefConfidence", "GVCF",
        "--variant_index_type", "LINEAR",
        "--variant_index_parameter", "128000",
        "--sample_ploidy", ploidy,
        "-o", out_path,
        "-l", "INFO"
        ]
    return _execute(gatk_args, java_mem=java_mem, **kwargs)


def genotype_gvcfs(ref_file, interval_list_file, gvcf_files, out_path, **kwargs):
    java_mem = kwargs.pop("java_mem", "8g")
    cores = kwargs.pop("cores", "2")
    print "combine_gvcfs called with ref_file=[%s] interval_list_file=[%s] gvcf_files=[%s] out_path=[%s] java_mem=[%s] cores=[%s] **kwargs=[%s]" % (ref_file, interval_list_file, ' '.join(gvcf_files), out_path, java_mem, cores, ' '.join(['%s = %s' % (k,v) for k,v in kwargs.items()]))
    # Call GATK GenotypeGVCFs
    gatk_args = [
            "-T", "GenotypeGVCFs",
            "--no_cmdline_in_header",
            "-R", ref_file,
            "-L", interval_list_file,
            "--max_alternate_alleles", "6",
            "--annotateNDA",
            "-nt", cores]
    for gvcf_file in gvcf_files:
        gatk_args.extend(["--variant", gvcf_file])
    gatk_args.extend([
        "-o", out_path
    ])
    return _execute(gatk_args, java_mem=java_mem, **kwargs)
