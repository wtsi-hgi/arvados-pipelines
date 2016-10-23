#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess

from hgi_arvados import errors

def _execute(bcftools_args, **kwargs):
    output_prefix = kwargs.pop("output_prefix", "bcftools: ")
    if len(kwargs) > 0:
        print "Extraneous keyword arguments passed to _execute: %s" %(kwargs)
    print "Calling %s%s" % (output_prefix, bcftools_args)
    bcftools_p = subprocess.Popen(
        bcftools_args,
        stdin=None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        close_fds=True,
        shell=False)

    while bcftools_p.poll() is None:
        line = bcftools_p.stdout.readline()
        print "%s%s" % (output_prefix, line.rstrip())

    bcftools_exit = bcftools_p.wait()
    return bcftools_exit


def concat(vcf_files, out_path, **kwargs):
    print "bcftools concat called with vcf_files=[%s] out_path=[%s] **kwargs=[%s]" % (' '.join(vcf_files), out_path, ' '.join(['%s = %s' % (k,v) for k,v in kwargs.items()]))
    # Call bcftools concat
    bcftools_args = [
            "bcftools", "concat",
            "-Oz",
            "-o", out_path,
    ]
    bcftools_args.extend(vcf_files)
    return _execute(bcftools_args, **kwargs)

def index(vcf_file, **kwargs):
    print "bcftools index called with vcf_file=[%s] **kwargs=[%s]" % (vcf_file, ' '.join(['%s = %s' % (k,v) for k,v in kwargs.items()]))
    # Call bcftools index
    bcftools_args = [
        "bcftools", "index",
        vcf_file
    ]
    return _execute(bcftools_args, **kwargs)
