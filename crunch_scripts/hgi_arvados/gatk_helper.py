#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import sys

from hgi_arvados import errors

def prepare_gatk_reference_collection(reference_coll):
    """
    Checks that the supplied reference_collection has the required
    files and only the required files for GATK.
    Returns: a portable data hash for the reference collection
    """
    # Ensure we have a .fa reference file with corresponding .fai index and .dict
    # see: http://gatkforums.broadinstitute.org/discussion/1601/how-can-i-prepare-a-fasta-file-to-use-as-reference
    rcr = arvados.CollectionReader(reference_coll)
    ref_fasta = {}
    ref_fai = {}
    ref_dict = {}
    ref_input = None
    dict_reader = None
    for rs in rcr.all_streams():
        for rf in rs.all_files():
            if re.search(r'\.fa$', rf.name()):
                ref_fasta[rs.name(), rf.name()] = rf
            elif re.search(r'\.fai$', rf.name()):
                ref_fai[rs.name(), rf.name()] = rf
            elif re.search(r'\.dict$', rf.name()):
                ref_dict[rs.name(), rf.name()] = rf
    for ((s_name, f_name), fasta_f) in ref_fasta.items():
        fai_f = ref_fai.get((s_name, re.sub(r'fa$', 'fai', f_name)),
                            ref_fai.get((s_name, re.sub(r'fa$', 'fa.fai', f_name)),
                                        None))
        dict_f = ref_dict.get((s_name, re.sub(r'fa$', 'dict', f_name)),
                              ref_dict.get((s_name, re.sub(r'fa$', 'fa.dict', f_name)),
                                           None))
        if fasta_f and fai_f and dict_f:
            # found a set of all three!
            ref_input = fasta_f.as_manifest()
            ref_input += fai_f.as_manifest()
            ref_input += dict_f.as_manifest()
            dict_reader = dict_f
            break
    if ref_input is None:
        raise errors.InvalidArgumentError("Expected a reference fasta with fai and dict in reference_collection. Found [%s]" % ' '.join(rf.name() for rf in rs.all_files()))
    if dict_reader is None:
        raise errors.InvalidArgumentError("Could not find .dict file in reference_collection. Found [%s]" % ' '.join(rf.name() for rf in rs.all_files()))
    # Create and return a portable data hash for the ref_input manifest
    try:
        r = arvados.api().collections().create(body={"manifest_text": ref_input}).execute()
        ref_input_pdh = r["portable_data_hash"]
    except:
        raise
    return ref_input_pdh

def mount_gatk_reference(ref_param="ref"):
    # Get reference FASTA
    print "Mounting reference FASTA collection"
    ref_dir = arvados.get_task_param_mount(ref_param)

    # Sanity check reference FASTA
    for f in arvados.util.listdir_recursive(ref_dir):
        if re.search(r'\.fa$', f):
            ref_file = os.path.join(ref_dir, f)
    if ref_file is None:
        raise errors.InvalidArgumentError("No reference fasta found in reference collection.")
    # Ensure we can read the reference file
    if not os.access(ref_file, os.R_OK):
        raise errors.FileAccessError("reference FASTA file not readable: %s" % ref_file)
    # TODO: could check readability of .fai and .dict as well?
    return ref_file

def mount_gatk_cram_input(input_param="input"):
    # Get single CRAM file for this task
    print "Mounting task input collection"
    input_dir = arvados.get_task_param_mount('input')

    input_cram_files = []
    for f in arvados.util.listdir_recursive(input_dir):
        if re.search(r'\.cram$', f):
            stream_name, input_file_name = os.path.split(f)
            input_cram_files += [os.path.join(input_dir, f)]
    if len(input_cram_files) != 1:
        raise errors.InvalidArgumentError("Expected exactly one cram file per task.")

    # There is only one CRAM file
    cram_file = input_cram_files[0]

    # Ensure we can read the CRAM file
    if not os.access(cram_file, os.R_OK):
        raise errors.FileAccessError("CRAM file not readable: %s" % cram_file)

    # Ensure we have corresponding CRAI index and can read it as well
    cram_file_base, cram_file_ext = os.path.splitext(cram_file)
    assert(cram_file_ext == ".cram")
    crai_file = cram_file_base + ".crai"
    if not os.access(crai_file, os.R_OK):
        crai_file = cram_file_base + ".cram.crai"
        if not os.access(crai_file, os.R_OK):
            raise errors.FileAccessError("No readable CRAM index file for CRAM file: %s" % cram_file)
    return cram_file

def mount_gatk_bam_input(input_param="input"):
    # Get single BAM file for this task
    print "Mounting task input collection"
    input_dir = arvados.get_task_param_mount('input')

    input_bam_files = []
    for f in arvados.util.listdir_recursive(input_dir):
        if re.search(r'\.bam$', f):
            stream_name, input_file_name = os.path.split(f)
            input_bam_files += [os.path.join(input_dir, f)]
    if len(input_bam_files) != 1:
        raise errors.InvalidArgumentError("Expected exactly one bam file per task.")

    # There is only one BAM file
    bam_file = input_bam_files[0]

    # Ensure we can read the BAM file
    if not os.access(bam_file, os.R_OK):
        raise errors.FileAccessError("BAM file not readable: %s" % bam_file)

    # Ensure we have corresponding BAI index and can read it as well
    bam_file_base, bam_file_ext = os.path.splitext(bam_file)
    assert(bam_file_ext == ".bam")
    bai_file = bam_file_base + ".bai"
    if not os.access(bai_file, os.R_OK):
        bai_file = bam_file_base + ".bam.bai"
        if not os.access(bai_file, os.R_OK):
            raise errors.FileAccessError("No readable BAM index file for BAM file: %s" % bam_file)
    return bam_file

def mount_gatk_gvcf_inputs(inputs_param="inputs"):
    # Get input gVCFs for this task
    print "Mounting task input collection"
    inputs_dir = ""
    if inputs_param in arvados.current_task()['parameters']:
        inputs_dir = arvados.get_task_param_mount(inputs_param)
    else:
        inputs_dir = arvados.get_job_param_mount(inputs_param)

    # Sanity check input gVCFs
    input_gvcf_files = []
    for f in arvados.util.listdir_recursive(inputs_dir):
        if re.search(r'\.vcf\.gz$', f):
            input_gvcf_files.append(os.path.join(inputs_dir, f))
        elif re.search(r'\.tbi$', f):
            pass
        elif re.search(r'\.interval_list$', f):
            pass
        else:
            print "WARNING: collection contains unexpected file %s" % f
    if len(input_gvcf_files) == 0:
        raise errors.InvalidArgumentError("Expected one or more .vcf.gz files in collection (found 0 while recursively searching %s)" % inputs_dir)

    # Ensure we can read the gVCF files and that they each have an index
    for gvcf_file in input_gvcf_files:
        if not os.access(gvcf_file, os.R_OK):
            raise errors.FileAccessError("gVCF file not readable: %s" % gvcf_file)

        # Ensure we have corresponding .tbi index and can read it as well
        (gvcf_file_base, gvcf_file_ext) = os.path.splitext(gvcf_file)
        assert(gvcf_file_ext == ".gz")
        tbi_file = gvcf_file_base + ".gz.tbi"
        if not os.access(tbi_file, os.R_OK):
            tbi_file = gvcf_file_base + ".tbi"
            if not os.access(tbi_file, os.R_OK):
                raise errors.FileAccessError("No readable gVCF index file for gVCF file: %s" % gvcf_file)
    return input_gvcf_files

def mount_single_gatk_interval_list_input(interval_list_param="interval_list"):
    # Get interval_list for this task
    print "Mounting task input collection to get interval_list"
    interval_list_dir = arvados.get_task_param_mount(interval_list_param)
    print "Interval_List collection mounted at %s" % (interval_list_dir)

    # Sanity check input interval_list (there can be only one)
    input_interval_lists = []
    for f in arvados.util.listdir_recursive(interval_list_dir):
        if re.search(r'\.interval_list$', f):
            input_interval_lists.append(os.path.join(interval_list_dir, f))
    if len(input_interval_lists) != 1:
        raise errors.InvalidArgumentError("Expected exactly one interval_list in input collection (found %s)" % len(input_interval_lists))

    assert(len(input_interval_lists) == 1)
    interval_list_file = input_interval_lists[0]

    if not os.access(interval_list_file, os.R_OK):
        raise errors.FileAccessError("interval_list file not readable: %s" % interval_list_file)

    return interval_list_file

if __name__ == '__main__':
    print "This module is not intended to be executed as a script"
    sys.exit(1)
