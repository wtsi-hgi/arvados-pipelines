#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess

import hgi_arvados
from hgi_arvados import gatk
from hgi_arvados import gatk_helper

BGZF_EOF="\x1f\x8b\x08\x04\x00\x00\x00\x00\x00\xff\x06\x00\x42\x43\x02\x00\x1b\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00"

def validate_task_output(output_locator):
    print "Validating task output %s" % (output_locator)
    output_reader = arvados.collection.CollectionReader(output_locator)
    vcf_files = {}
    vcf_indices = {}
    for output_stream in output_reader.all_streams():
        for output_file in output_stream.all_files():
            if re.search(r'\.vcf\.gz$', output_file.name()):
                vcf_files[(output_stream.name(), output_file.name())] = output_file
            elif re.search(r'\.tbi$', output_file.name()):
                vcf_indices[(output_stream.name(), output_file.name())] = output_file
            else:
                print "WARNING: unexpected file in task output - ignoring %s" % (output_file.name())

    # verify that we got some VCFs
    if len(vcf_files) <= 0:
        print "ERROR: found no VCF files in collection"
        return False

    print "Have %s VCF files to validate" % (len(vcf_files))
    for ((stream_name, file_name), vcf) in vcf_files.items():
        vcf_path = os.path.join(stream_name, file_name)
        # verify that VCF is sizeable
        if vcf.size() < 128:
            print "ERROR: Small VCF file %s - INVALID!" % (vcf_path)
            return False
        print "Have VCF file %s of %s bytes" % (vcf_path, vcf.size())

        # verify that BGZF EOF block is intact
        eof_block = vcf.readfrom(vcf.size()-28, 28, num_retries=10)
        if eof_block != BGZF_EOF:
            print "ERROR: VCF BGZF EOF block was missing or incorrect: %s" % (':'.join("{:02x}".format(ord(c)) for c in eof_block))
            return False

        # verify index exists
        tbi = vcf_indices.get((stream_name, re.sub(r'gz$', 'gz.tbi', file_name)),
                              None)
        if tbi is None:
            print "ERROR: could not find index .tbi for VCF: %s" % (vcf_path)
            return False

        # verify index is sizeable
        if tbi.size() < 128:
            print "ERROR: .tbi index was too small for VCF %s (%s): %s bytes" % (vcf_path, tbi.name(), tbi.size())
            return False

    return True

def main():
    ################################################################################
    # Phase I: Check inputs and setup sub tasks 1-N to process group(s) based on
    #          applying the capturing group named "group_by" in group_by_regex.
    #          (and terminate if this is task 0)
    ################################################################################
    ref_input_pdh = gatk_helper.prepare_gatk_reference_collection(reference_coll=arvados.current_job()['script_parameters']['reference_collection'])
    job_input_pdh = arvados.current_job()['script_parameters']['inputs_collection']
    interval_lists_pdh = arvados.current_job()['script_parameters']['interval_lists_collection']
    interval_count = 1
    if "interval_count" in arvados.current_job()['script_parameters']:
        interval_count = arvados.current_job()['script_parameters']['interval_count']

    # Setup sub tasks 1-N (and terminate if this is task 0)
    # TODO: add interval_list
    hgi_arvados.chunked_tasks_per_cram_file(ref_input_pdh, job_input_pdh, interval_lists_pdh, validate_task_output,
                                            if_sequence=0, and_end_task=True, reuse_tasks=False,
                                            oldest_git_commit_to_reuse='6ca726fc265f9e55765bf1fdf71b86285b8a0ff2',
                                            script="gatk-haplotypecaller-cram.py")

    # Get object representing the current task
    this_task = arvados.current_task()

    # We will never reach this point if we are in the 0th task
    assert(this_task['sequence'] != 0)

    ################################################################################
    # Phase IIa: If we are a "reuse" task, just set our output and be done with it
    ################################################################################
    if 'reuse_job_task' in this_task['parameters']:
        print "This task's work was already done by JobTask %s" % this_task['parameters']['reuse_job_task']
        exit(0)

    ################################################################################
    # Phase IIb: Call Haplotypes!
    ################################################################################
    ref_file = gatk_helper.mount_gatk_reference(ref_param="ref")
    interval_list_file = gatk_helper.mount_single_gatk_interval_list_input(interval_list_param="chunk")
    cram_file = gatk_helper.mount_gatk_cram_input(input_param="input")
    cram_file_base, cram_file_ext = os.path.splitext(cram_file)
    out_dir = hgi_arvados.prepare_out_dir()
    out_filename = os.path.basename(cram_file_base) + "." + os.path.basename(interval_list_file) + ".g.vcf.gz"
    # HaplotypeCaller!
    gatk_exit = gatk.haplotype_caller(ref_file, cram_file, interval_list_file, os.path.join(out_dir, out_filename))

    if gatk_exit != 0:
        print "ERROR: GATK exited with exit code %s (NOT WRITING OUTPUT)" % gatk_exit
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':False}
                                         ).execute()
    else:
        print "GATK exited successfully, writing output to keep"

        # Write a new collection as output
        out = arvados.CollectionWriter()

        # Write out_dir to keep
        out.write_directory_tree(out_dir)

        # Commit the output to Keep.
        output_locator = out.finish()

        print "Task output written to keep, validating it"
        if validate_task_output(output_locator):
            print "Task output validated, setting output to %s" % (output_locator)

            # Use the resulting locator as the output for this task.
            this_task.set_output(output_locator)
        else:
            print "ERROR: Failed to validate task output (%s)" % (output_locator)
            arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                             body={'success':False}
                                             ).execute()


    # Done!


if __name__ == '__main__':
    main()
