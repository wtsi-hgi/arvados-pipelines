#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess

import hgi_arvados
from hgi_arvados import gatk
from hgi_arvados import gatk_helper
from hgi_arvados import errors
from hgi_arvados import validators

# TODO: make group_by_regex and max_gvcfs_to_combine parameters
group_by_regex = '[._](?P<group_by>[0-9]+_of_[0-9]+)[._]'
max_gvcfs_to_combine = 200
interval_count = 1

def validate_task_output(output_locator):
    print "Validating task output %s" % (output_locator)
    return validators.validate_compressed_indexed_vcf_collection(output_locator)

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
    hgi_arvados.one_task_per_group_and_per_n_gvcfs(ref_input_pdh, job_input_pdh, interval_lists_pdh,
                                                   group_by_regex, max_gvcfs_to_combine,
                                                   if_sequence=0, and_end_task=True)

    # Get object representing the current task
    this_task = arvados.current_task()

    # We will never reach this point if we are in the 0th task sequence
    assert(this_task['sequence'] > 0)

    ################################################################################
    # Phase II: Combine gVCFs!
    ################################################################################
    ref_file = gatk_helper.mount_gatk_reference(ref_param="ref")
    gvcf_files = gatk_helper.mount_gatk_gvcf_inputs(inputs_param="inputs")
    out_dir = hgi_arvados.prepare_out_dir()
    interval_list_file = gatk_helper.mount_single_gatk_interval_list_input(interval_list_param="interval_list")
    name = this_task['parameters'].get('name')
    if not name:
        name = "unknown"
    out_file = name + ".vcf.gz"

    # because of a GATK bug, name cannot contain the string '.bcf' anywhere within it or we will get BCF output
    out_file = out_file.replace(".bcf", "._cf")

    # CombineGVCFs!
    extra_args = []
    extra_args.extend(["--breakBandsAtMultiplesOf", "1000000"])
    gatk_exit = gatk.combine_gvcfs(ref_file, gvcf_files, interval_list_file, os.path.join(out_dir, out_file), extra_gatk_args=extra_args)

    if gatk_exit != 0:
        print "WARNING: GATK exited with exit code %s (NOT WRITING OUTPUT)" % gatk_exit
        arvados.api().job_tasks().update(uuid=this_task['uuid'],
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

        if validate_task_output(output_locator):
            print "Task output validated, setting output to %s" % (output_locator)

            # Use the resulting locator as the output for this task.
            this_task.set_output(output_locator)
        else:
            print "ERROR: Failed to validate task output (%s)" % (output_locator)
            arvados.api().job_tasks().update(uuid=this_task['uuid'],
                                             body={'success':False}
                                             ).execute()

    # Done!


if __name__ == '__main__':
    main()
