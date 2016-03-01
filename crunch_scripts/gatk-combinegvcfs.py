#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess

import hgi_arvados
from hgi_arvados import errors
from hgi_arvados import gatk

# TODO: make group_by_regex and max_gvcfs_to_combine parameters
group_by_regex = '[.](?P<group_by>[0-9]+_of_[0-9]+)[.]'
max_gvcfs_to_combine = 200
interval_count = 1

def main():
    ################################################################################
    # Phase I: Check inputs and setup sub tasks 1-N to process group(s) based on
    #          applying the capturing group named "group_by" in group_by_regex.
    #          (and terminate if this is task 0)
    ################################################################################
    ref_input_pdh = gatk.prepare_gatk_reference_collection(reference_coll=arvados.current_job()['script_parameters']['reference_collection'])
    hgi_arvados.one_task_per_group_and_per_n_gvcfs(group_by_regex, max_gvcfs_to_combine,
                                                   ref_input_pdh,
                                                   if_sequence=0, and_end_task=True)

    # We will never reach this point if we are in the 0th task sequence
    assert(arvados.current_task()['sequence'] > 0)

    ################################################################################
    # Phase II: Read interval_list and split into additional intervals
    ################################################################################
    hgi_arvados.one_task_per_interval(interval_count,
                                      reuse_tasks=True,
                                      if_sequence=1, and_end_task=True)

    # We will never reach this point if we are in the 1st task sequence
    assert(arvados.current_task()['sequence'] > 1)

    ################################################################################
    # Phase IIIa: If we are a "reuse" task, just set our output and be done with it
    ################################################################################
    if 'reuse_job_task' in arvados.current_task()['parameters']:
        print "This task's work was already done by JobTask %s" % arvados.current_task()['parameters']['reuse_job_task']
        exit(0)

    ################################################################################
    # Phase IIIb: Combine gVCFs!
    ################################################################################
    ref_file = gatk_helper.mount_gatk_reference(ref_param="ref")
    gvcf_files = gatk_helper.mount_gatk_gvcf_inputs(inputs_param="inputs")
    out_dir = hgi_arvados.prepare_out_dir()
    name = arvados.current_task()['parameters'].get('name')
    if not name:
        name = "unknown"
    interval_str = arvados.current_task()['parameters'].get('interval')
    if not interval_str:
        interval_str = ""
    interval_strs = interval_str.split()
    intervals = []
    for interval in interval_strs:
        intervals.extend(["--intervals", interval])
    out_file = name + ".g.vcf.gz"
    if interval_count > 1:
        out_file = name + "." + '_'.join(interval_strs) + ".g.vcf.gz"
        if len(out_file) > 255:
            out_file = name + "." + '_'.join([interval_strs[0], interval_strs[-1]]) + ".g.vcf.gz"
            print "Output file name was too long with full interval list, shortened it to: %s" % out_file
        if len(out_file) > 255:
            raise errors.InvalidArgumentError("Output file name is too long, cannot continue: %s" % out_file)

    # CombineGVCFs!
    gatk_exit = gatk.combine_gvcfs(ref_file, gvcf_files, os.path.join(out_dir, out_file), extra_args=intervals)

    if gatk_exit != 0:
        print "WARNING: GATK exited with exit code %s (NOT WRITING OUTPUT)" % gatk_exit
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

        # Use the resulting locator as the output for this task.
        arvados.current_task().set_output(output_locator)

    # Done!


if __name__ == '__main__':
    main()
