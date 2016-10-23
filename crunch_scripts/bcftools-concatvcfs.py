#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess

import hgi_arvados
from hgi_arvados import bcftools
from hgi_arvados import gatk_helper
from hgi_arvados import errors
from hgi_arvados import validators

# TODO: make sort_by_regex a parameter
sort_by_regex = '(?P<sort_by>[0-9]+)_of_[0-9]+[^0-9]'

def validate_task_output(output_locator):
    print "Validating task output %s" % (output_locator)
    return validators.validate_compressed_indexed_vcf_collection(output_locator)

def main():
    # Get object representing the current task
    this_task = arvados.current_task()

    sort_by_r = re.compile(sort_by_regex)

    ################################################################################
    # Concatentate VCFs in numerically sorted order of sort_by_regex
    ################################################################################
    vcf_files = gatk_helper.mount_gatk_gvcf_inputs(inputs_param="inputs")
    out_dir = hgi_arvados.prepare_out_dir()
    output_prefix = arvados.current_job()['script_parameters']['output_prefix']
    out_file = output_prefix + ".vcf.gz"

    # Concatenate VCFs
    bcftools_concat_exit = bcftools.concat(sorted(vcf_files, key=lambda fn: int(re.search(sort_by_r, fn).group('sort_by'))),
                                    os.path.join(out_dir, out_file))

    if bcftools_concat_exit != 0:
        print "WARNING: bcftools concat exited with exit code %s (NOT WRITING OUTPUT)" % bcftools_concat_exit
        arvados.api().job_tasks().update(uuid=this_task['uuid'],
                                         body={'success':False}
                                         ).execute()
    else:
        print "bcftools concat exited successfully, indexing"

        bcftools_index_exit = bcftools.index(os.path.join(out_dir, out_file))

        if bcftools_index_exit != 0:
            print "WARNING: bcftools index exited with exit code %s (NOT WRITING OUTPUT)" % bcftools_index_exit
            arvados.api().job_tasks().update(uuid=this_task['uuid'],
                                             body={'success':False}
                                         ).execute()
        else:
            print "bcftools index exited successfully, writing output to keep"


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
