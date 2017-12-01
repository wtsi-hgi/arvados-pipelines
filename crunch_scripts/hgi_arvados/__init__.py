#!/usr/bin/env python
################################################################################
# Copyright (c) 2015, 2016 Genome Research Ltd.
#
# Author: Joshua C. Randall <jcrandall@alum.mit.edu>
#
# This file is part of HGI Arvados Pipelines.
#
# HGI Arvados Pipelines is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
################################################################################

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import sys
import json

import gatk_helper

import errors
__all__ = ["errors", "gatk", "gatk_helper", "validators"]

def create_task(sequence, params):
    new_task_attrs = {
        'job_uuid': arvados.current_job()['uuid'],
        'created_by_job_task_uuid': arvados.current_task()['uuid'],
        'sequence': sequence,
        'parameters': params
    }
    task = arvados.api().job_tasks().create(body=new_task_attrs).execute()
    return task

def chunked_tasks_per_cram_file(ref_input, job_input, interval_lists, validate_task_output,
                                if_sequence=0, and_end_task=True,
                                reuse_tasks=True, reuse_tasks_retrieve_all=True,
                                interval_list_param="interval_list",
                                ploidy=2,
                                oldest_git_commit_to_reuse='6ca726fc265f9e55765bf1fdf71b86285b8a0ff2',
                                script=arvados.current_job()['script']):
    """
    Queue one task for each cram file in this job's input collection.
    Each new task will have an "input" parameter: a manifest
    containing one .cram file and its corresponding .crai index file.
    Files in the input collection that are not named *.cram or *.crai
    (as well as *.crai files that do not match any .cram file present)
    are silently ignored.
    if_sequence and and_end_task arguments have the same significance
    as in arvados.job_setup.one_task_per_input_file().
    """
    if if_sequence != arvados.current_task()['sequence']:
        return

    # prepare interval lists
    cr = arvados.CollectionReader(interval_lists)
    chunk_interval_list = {}
    chunk_input_pdh_names = []
    for s in cr.all_streams():
        for f in s.all_files():
            if re.search(r'\.interval_list$', f.name()):
                chunk_interval_list[s.name(), f.name()] = f
    for ((s_name, f_name), chunk_interval_list_f) in sorted(chunk_interval_list.items()):
        chunk_input = chunk_interval_list_f.as_manifest()
        try:
            r = arvados.api().collections().create(body={"manifest_text": chunk_input}).execute()
            chunk_input_pdh = r["portable_data_hash"]
            chunk_input_name = os.path.join(s_name, f_name)
            chunk_input_pdh_names.append((chunk_input_pdh, chunk_input_name))
        except:
            raise

    if len(chunk_input_pdh_names) == 0:
        raise errors.InvalidArgumentError("No interval_list files found in %s" % (interval_lists))

    # prepare CRAM input collections
    cr = arvados.CollectionReader(job_input)
    cram = {}
    crai = {}
    for s in cr.all_streams():
        for f in s.all_files():
            if re.search(r'\.cram$', f.name()):
                cram[s.name(), f.name()] = f
            elif re.search(r'\.crai$', f.name()):
                crai[s.name(), f.name()] = f
    for ((s_name, f_name), cram_f) in cram.items():
        crai_f = crai.get((s_name, re.sub(r'cram$', 'crai', f_name)),
                          crai.get((s_name, re.sub(r'cram$', 'cram.crai', f_name)),
                                   None))
        task_input = cram_f.as_manifest()
        if crai_f:
            task_input += crai_f.as_manifest()
        else:
            # no CRAI for CRAM
            raise errors.InvalidArgumentError("No correponding CRAI file found for CRAM file %s" % f_name)

        # Create a portable data hash for the task's subcollection
        try:
            r = arvados.api().collections().create(body={"manifest_text": task_input}).execute()
            task_input_pdh = r["portable_data_hash"]
        except:
            raise

        if reuse_tasks:
            task_key_params=['input', 'ref', 'chunk']
            # get candidates for task reuse
            job_filters = [
                ['script', '=', script],
                ['repository', '=', arvados.current_job()['repository']],
                ['script_version', 'in git', oldest_git_commit_to_reuse],
                ['docker_image_locator', 'in docker', arvados.current_job()['docker_image_locator']],
            ]
            if reuse_tasks_retrieve_all:
                # retrieve a full set of all possible reusable tasks
                reusable_tasks = get_reusable_tasks(if_sequence + 1, task_key_params, job_filters)
                print "Have %s tasks for potential reuse" % (len(reusable_tasks))
            else:
                reusable_task_jobs = get_jobs_for_task_reuse(job_filters)
                print "Have %s jobs for potential task reuse" % (len(reusable_task_jobs))
                reusable_task_job_uuids = [job['uuid'] for job in reusable_task_jobs['items']]

        for chunk_input_pdh, chunk_input_name in chunk_input_pdh_names:
            # Create task for each CRAM / chunk
            new_task_params = {
                'input': task_input_pdh,
                'ref': ref_input,
                'chunk': chunk_input_pdh,
                'ploidy': ploidy
            }
            print "Creating new task to process %s with chunk interval %s (ploidy %s)" % (f_name, chunk_input_name, ploidy)
            if reuse_tasks:
                if reuse_tasks_retrieve_all:
                    task = create_or_reuse_task(if_sequence + 1, new_task_params, reusable_tasks, task_key_params, validate_task_output)
                else:
                    task = create_or_reuse_task_from_jobs(if_sequence + 1, new_task_params, reusable_task_job_uuids, task_key_params, validate_task_output)
            else:
                task = create_task(if_sequence + 1, new_task_params)

    if and_end_task:
        print "Ending task 0 successfully"
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':True}
                                         ).execute()
        exit(0)

def chunked_tasks_per_bam_file(ref_input, job_input, interval_lists, validate_task_output,
                                if_sequence=0, and_end_task=True,
                                reuse_tasks=True, reuse_tasks_retrieve_all=True,
                                interval_list_param="interval_list",
                                oldest_git_commit_to_reuse='6ca726fc265f9e55765bf1fdf71b86285b8a0ff2',
                                script=arvados.current_job()['script']):
    """
    Queue one task for each bam file in this job's input collection.
    Each new task will have an "input" parameter: a manifest
    containing one .bam file and its corresponding .bai index file.
    Files in the input collection that are not named *.bam or *.bai
    (as well as *.bai files that do not match any .bam file present)
    are silently ignored.
    if_sequence and and_end_task arguments have the same significance
    as in arvados.job_setup.one_task_per_input_file().
    """
    if if_sequence != arvados.current_task()['sequence']:
        return

    # prepare interval lists
    cr = arvados.CollectionReader(interval_lists)
    chunk_interval_list = {}
    chunk_input_pdh_names = []
    for s in cr.all_streams():
        for f in s.all_files():
            if re.search(r'\.interval_list$', f.name()):
                chunk_interval_list[s.name(), f.name()] = f
    for ((s_name, f_name), chunk_interval_list_f) in sorted(chunk_interval_list.items()):
        chunk_input = chunk_interval_list_f.as_manifest()
        try:
            r = arvados.api().collections().create(body={"manifest_text": chunk_input}).execute()
            chunk_input_pdh = r["portable_data_hash"]
            chunk_input_name = os.path.join(s_name, f_name)
            chunk_input_pdh_names.append((chunk_input_pdh, chunk_input_name))
        except:
            raise

    if len(chunk_input_pdh_names) == 0:
        raise errors.InvalidArgumentError("No interval_list files found in %s" % (interval_lists))

    # prepare BAM input collections
    cr = arvados.CollectionReader(job_input)
    bam = {}
    bai = {}
    for s in cr.all_streams():
        for f in s.all_files():
            if re.search(r'\.bam$', f.name()):
                bam[s.name(), f.name()] = f
            elif re.search(r'\.bai$', f.name()):
                bai[s.name(), f.name()] = f
    for ((s_name, f_name), bam_f) in bam.items():
        bai_f = bai.get((s_name, re.sub(r'bam$', 'bai', f_name)),
                          bai.get((s_name, re.sub(r'bam$', 'bam.bai', f_name)),
                                   None))
        task_input = bam_f.as_manifest()
        if bai_f:
            task_input += bai_f.as_manifest()
        else:
            # no BAI for BAM
            raise errors.InvalidArgumentError("No correponding BAI file found for BAM file %s" % f_name)

        # Create a portable data hash for the task's subcollection
        try:
            r = arvados.api().collections().create(body={"manifest_text": task_input}).execute()
            task_input_pdh = r["portable_data_hash"]
        except:
            raise

        if reuse_tasks:
            task_key_params=['input', 'ref', 'chunk']
            # get candidates for task reuse
            job_filters = [
                ['script', '=', script],
                ['repository', '=', arvados.current_job()['repository']],
                ['script_version', 'in git', oldest_git_commit_to_reuse],
                ['docker_image_locator', 'in docker', arvados.current_job()['docker_image_locator']],
            ]
            if reuse_tasks_retrieve_all:
                # retrieve a full set of all possible reusable tasks
                reusable_tasks = get_reusable_tasks(if_sequence + 1, task_key_params, job_filters)
                print "Have %s tasks for potential reuse" % (len(reusable_tasks))
            else:
                reusable_task_jobs = get_jobs_for_task_reuse(job_filters)
                print "Have %s jobs for potential task reuse" % (len(reusable_task_jobs))
                reusable_task_job_uuids = [job['uuid'] for job in reusable_task_jobs['items']]

        for chunk_input_pdh, chunk_input_name in chunk_input_pdh_names:
            # Create task for each BAM / chunk
            new_task_params = {
                'input': task_input_pdh,
                'ref': ref_input,
                'chunk': chunk_input_pdh
            }
            print "Creating new task to process %s with chunk interval %s " % (f_name, chunk_input_name)
            if reuse_tasks:
                if reuse_tasks_retrieve_all:
                    task = create_or_reuse_task(if_sequence + 1, new_task_params, reusable_tasks, task_key_params, validate_task_output)
                else:
                    task = create_or_reuse_task_from_jobs(if_sequence + 1, new_task_params, reusable_task_job_uuids, task_key_params, validate_task_output)
            else:
                task = create_task(if_sequence + 1, new_task_params)

    if and_end_task:
        print "Ending task 0 successfully"
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':True}
                                         ).execute()
        exit(0)

def one_task_per_gvcf_group_in_stream(stream_name, gvcf_by_group, gvcf_indices, interval_list_by_group, if_sequence, ref_input_pdh, create_task_func=create_task):
    """
    Process one stream of data and launch a subtask for handling it
    """
    print "Finalising stream %s" % stream_name
    for group_name in sorted(gvcf_by_group.keys()):
        print "Have %s gVCFs in group %s" % (len(gvcf_by_group[group_name]), group_name)
        # require interval_list for this group
        if group_name not in interval_list_by_group:
            raise errors.InvalidArgumentError("Inputs collection did not contain interval_list for group %s" % group_name)
        interval_lists = interval_list_by_group[group_name].keys()
        if len(interval_lists) > 1:
            raise errors.InvalidArgumentError("Inputs collection contained more than one interval_list for group %s: %s" % (group_name, ' '.join(interval_lists)))
        interval_list_manifest = interval_list_by_group[group_name].get(interval_lists[0]).as_manifest()
        # Create a portable data hash for the task's interval_list
        try:
            r = arvados.api().collections().create(body={"manifest_text": interval_list_manifest}).execute()
            interval_list_pdh = r["portable_data_hash"]
        except:
            raise

        task_inputs_manifest = ""
        for ((s_name, gvcf_name), gvcf_f) in gvcf_by_group[group_name].items():
            task_inputs_manifest += gvcf_f.as_manifest()
            gvcf_index_f = gvcf_indices.get((s_name, re.sub(r'vcf.gz$', 'vcf.tbi', gvcf_name)),
                                            gvcf_indices.get((s_name, re.sub(r'vcf.gz$', 'vcf.gz.tbi', gvcf_name)),
                                                             None))
            if gvcf_index_f:
                task_inputs_manifest += gvcf_index_f.as_manifest()
            else:
                # no index for gVCF - TODO: should this be an error or warning?
                print "WARNING: No correponding .tbi index file found for gVCF file %s" % gvcf_name
                #raise errors.InvalidArgumentError("No correponding .tbi index file found for gVCF file %s" % gvcf_name)

        # Create a portable data hash for the task's subcollection
        try:
            r = arvados.api().collections().create(body={"manifest_text": task_inputs_manifest}).execute()
            task_inputs_pdh = r["portable_data_hash"]
        except:
            raise

        # Create task to process this group
        name_components = []
        if len(stream_name) > 0 and stream_name != ".":
            name_components.append(stream_name)
        if len(group_name) > 0:
            name_components.append(group_name)
        if len(name_components) == 0:
            name = "all"
        else:
            name = '::'.join(name_components)

        print "Creating task to process %s" % name
        new_task_params = {
                    'inputs': task_inputs_pdh,
                    'ref': ref_input_pdh,
                    'interval_list': interval_list_pdh,
                    'name': name
                    }
        task = create_task_func(if_sequence + 1, new_task_params)

def one_task_per_gvcf_group_in_stream_combined_inputs(stream_name, gvcf_by_group, gvcf_indices, interval_list_by_group, if_sequence, ref_input_pdh, create_task_func=create_task):
    """
    Process one stream of data and launch a subtask for handling it
    """
    print "Finalising stream %s" % stream_name
    for group_name in sorted(gvcf_by_group.keys()):
        print "Have %s gVCFs in group %s" % (len(gvcf_by_group[group_name]), group_name)
        # require interval_list for this group
        if group_name not in interval_list_by_group:
            raise errors.InvalidArgumentError("Inputs collection did not contain interval_list for group %s" % group_name)
        interval_lists = interval_list_by_group[group_name].keys()
        if len(interval_lists) > 1:
            raise errors.InvalidArgumentError("Inputs collection contained more than one interval_list for group %s: %s" % (group_name, ' '.join(interval_lists)))
        interval_list_manifest = interval_list_by_group[group_name].get(interval_lists[0]).as_manifest()

        # "combined_inputs" style is to have interval_list and inputs in same collection
        task_inputs_manifest = interval_list_manifest
        for ((s_name, gvcf_name), gvcf_f) in gvcf_by_group[group_name].items():
            task_inputs_manifest += gvcf_f.as_manifest()
            gvcf_index_f = gvcf_indices.get((s_name, re.sub(r'vcf.gz$', 'vcf.tbi', gvcf_name)),
                                            gvcf_indices.get((s_name, re.sub(r'vcf.gz$', 'vcf.gz.tbi', gvcf_name)),
                                                             None))
            if gvcf_index_f:
                task_inputs_manifest += gvcf_index_f.as_manifest()
            else:
                # no index for gVCF - TODO: should this be an error or warning?
                print "WARNING: No correponding .tbi index file found for gVCF file %s" % gvcf_name
                #raise errors.InvalidArgumentError("No correponding .tbi index file found for gVCF file %s" % gvcf_name)

        # Create a portable data hash for the task's subcollection
        try:
            r = arvados.api().collections().create(body={"manifest_text": task_inputs_manifest}).execute()
            task_inputs_pdh = r["portable_data_hash"]
        except:
            raise

        # Create task to process this group
        name_components = []
        if len(stream_name) > 0 and stream_name != ".":
            name_components.append(stream_name)
        if len(group_name) > 0:
            name_components.append(group_name)
        if len(name_components) == 0:
            name = "all"
        else:
            name = '::'.join(name_components)

        print "Creating task to process %s" % name
        new_task_params = {
                    'inputs': task_inputs_pdh,
                    'ref': ref_input_pdh,
                    'name': name
                    }
        task = create_task_func(if_sequence + 1, new_task_params)

def one_task_per_group_and_per_n_gvcfs(ref_input, job_input, interval_lists, group_by_regex, n, if_sequence=0, and_end_task=True, create_task_func=create_task):
    """
    Queue one task for each group of gVCFs and corresponding interval_list
    in the inputs_collection, with grouping based on three things:
      - the stream in which the gVCFs are held within the collection
      - the value of the named capture group "group_by" in the
        group_by_regex against the filename in the inputs_collection
      - a maximum size of n gVCFs in each group (i.e. if after
        splitting based on the above two groupings and there are more
        than n gVCFs in the resulting group, split it into as many
        groups as necessary to ensure there are <= n gVCFs in each
        group. If n<=0, don't perform this splitting.

    Each new task will have an "inputs" parameter: a manifest
    containing a set of one or more gVCF files and its corresponding
    index.

    Each new task will also have a "ref" parameter: a manifest
    containing the reference files to use.

    Note that all gVCFs not matching the group_by_regex are ignored.

    if_sequence and and_end_task arguments have the same significance
    as in arvados.job_setup.one_task_per_input_file().
    """
    if if_sequence != arvados.current_task()['sequence']:
        return

    group_by_r = re.compile(group_by_regex)

    # prepare interval_lists
    il_cr = arvados.CollectionReader(interval_lists)
    il_ignored_files = []
    interval_list_by_group = {}
    for s in il_cr.all_streams():
        for f in s.all_files():
            m = re.search(group_by_r, f.name())
            if m:
                group_name = m.group('group_by')
                interval_list_m = re.search(r'\.interval_list', f.name())
                if interval_list_m:
                    if group_name not in interval_list_by_group:
                        interval_list_by_group[group_name] = dict()
                    interval_list_by_group[group_name][s.name(), f.name()] = f
                    continue
            # if we make it this far, we have files that we are ignoring
            il_ignored_files.append("%s/%s" % (s.name(), f.name()))

    # prepare gVCF input collections
    cr = arvados.CollectionReader(job_input)
    ignored_files = []
    last_stream_name = ""
    gvcf_by_group = {}
    gvcf_indices = {}
    for s in sorted(cr.all_streams(), key=lambda stream: stream.name()):
        stream_name = s.name()
        # handle each stream name separately
        if stream_name != last_stream_name:
            if last_stream_name != "":
                print "Done processing files in stream %s" % last_stream_name
                one_task_per_gvcf_group_in_stream(last_stream_name, gvcf_by_group, gvcf_indices, interval_list_by_group, if_sequence, ref_input, create_task_func=create_task_func)
                # now that we are done with last_stream_name, reinitialise dicts to
                # process data from new stream
                print "Processing files in stream %s" % stream_name
                gvcf_by_group = {}
                gvcf_indices = {}
            last_stream_name = stream_name

        # loop over all the files in this stream (there may be only one)
        for f in s.all_files():
            if re.search(r'\.tbi$', f.name()):
                gvcf_indices[s.name(), f.name()] = f
                continue
            m = re.search(group_by_r, f.name())
            if m:
                group_name = m.group('group_by')
                gvcf_m = re.search(r'\.vcf\.gz$', f.name())
                if gvcf_m:
                    if group_name not in gvcf_by_group:
                        gvcf_by_group[group_name] = dict()
                    gvcf_by_group[group_name][s.name(), f.name()] = f
                    continue
                interval_list_m = re.search(r'\.interval_list', f.name())
                if interval_list_m:
                    if group_name not in interval_list_by_group:
                        interval_list_by_group[group_name] = dict()
                    if (s.name(), f.name()) in interval_list_by_group[group_name]:
                        if interval_list_by_group[group_name][s.name(), f.name()].as_manifest() != f.as_manifest():
                            raise errors.InvalidArgumentError("Already have interval_list for group %s file %s/%s, but manifests are not identical!" % (group_name, s.name(), f.name()))
                    else:
                        interval_list_by_group[group_name][s.name(), f.name()] = f
                    continue
            # if we make it this far, we have files that we are ignoring
            ignored_files.append("%s/%s" % (s.name(), f.name()))
    # finally, process the last stream
    print "Processing last stream"
    one_task_per_gvcf_group_in_stream(stream_name, gvcf_by_group, gvcf_indices, interval_list_by_group, if_sequence, ref_input, create_task_func=create_task_func)

    # report on any ignored files
    if len(ignored_files) > 0:
        print "WARNING: ignored non-matching files in inputs_collection: %s" % (' '.join(ignored_files))
        # TODO: could use `setmedian` from https://github.com/ztane/python-Levenshtein
        # to print most representative "median" filename (i.e. skipped 15 files like median), then compare the
        # rest of the files to that median (perhaps with `ratio`)

    if and_end_task:
        print "Ending task %s successfully" % if_sequence
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':True}
                                         ).execute()
        exit(0)

def one_task_per_group_combined_inputs(ref_input, job_input, interval_lists, group_by_regex, if_sequence=0, and_end_task=True, create_task_func=create_task):
    """
    Queue one task for each group of gVCFs and corresponding interval_list
    in the inputs_collection, with grouping based on three things:
      - the stream in which the gVCFs are held within the collection
      - the value of the named capture group "group_by" in the
        group_by_regex against the filename in the inputs_collection

    Each new task will have an "inputs" parameter: a manifest
    containing a set of one or more gVCF files and its corresponding
    index.

    Each new task will also have a "ref" parameter: a manifest
    containing the reference files to use.

    Note that all gVCFs not matching the group_by_regex are ignored.

    if_sequence and and_end_task arguments have the same significance
    as in arvados.job_setup.one_task_per_input_file().
    """
    if if_sequence != arvados.current_task()['sequence']:
        return

    group_by_r = re.compile(group_by_regex)

    # prepare interval_lists
    il_cr = arvados.CollectionReader(interval_lists)
    il_ignored_files = []
    interval_list_by_group = {}
    for s in il_cr.all_streams():
        for f in s.all_files():
            m = re.search(group_by_r, f.name())
            if m:
                group_name = m.group('group_by')
                interval_list_m = re.search(r'\.interval_list', f.name())
                if interval_list_m:
                    if group_name not in interval_list_by_group:
                        interval_list_by_group[group_name] = dict()
                    interval_list_by_group[group_name][s.name(), f.name()] = f
                    continue
            # if we make it this far, we have files that we are ignoring
            il_ignored_files.append("%s/%s" % (s.name(), f.name()))

    # prepare gVCF input collections
    cr = arvados.CollectionReader(job_input)
    ignored_files = []
    last_stream_name = ""
    gvcf_by_group = {}
    gvcf_indices = {}
    for s in sorted(cr.all_streams(), key=lambda stream: stream.name()):
        stream_name = s.name()
        # handle each stream name separately
        if stream_name != last_stream_name:
            if last_stream_name != "":
                print "Done processing files in stream %s" % last_stream_name
                one_task_per_gvcf_group_in_stream_combined_inputs(last_stream_name, gvcf_by_group, gvcf_indices, interval_list_by_group, if_sequence, ref_input, create_task_func=create_task_func)
                # now that we are done with last_stream_name, reinitialise dicts to
                # process data from new stream
                print "Processing files in stream %s" % stream_name
                gvcf_by_group = {}
                gvcf_indices = {}
            last_stream_name = stream_name

        # loop over all the files in this stream (there may be only one)
        for f in s.all_files():
            if re.search(r'\.tbi$', f.name()):
                gvcf_indices[s.name(), f.name()] = f
                continue
            m = re.search(group_by_r, f.name())
            if m:
                group_name = m.group('group_by')
                gvcf_m = re.search(r'\.vcf\.gz$', f.name())
                if gvcf_m:
                    if group_name not in gvcf_by_group:
                        gvcf_by_group[group_name] = dict()
                    gvcf_by_group[group_name][s.name(), f.name()] = f
                    continue
                interval_list_m = re.search(r'\.interval_list', f.name())
                if interval_list_m:
                    if group_name not in interval_list_by_group:
                        interval_list_by_group[group_name] = dict()
                    if (s.name(), f.name()) in interval_list_by_group[group_name]:
                        if interval_list_by_group[group_name][s.name(), f.name()].as_manifest() != f.as_manifest():
                            raise errors.InvalidArgumentError("Already have interval_list for group %s file %s/%s, but manifests are not identical!" % (group_name, s.name(), f.name()))
                    else:
                        interval_list_by_group[group_name][s.name(), f.name()] = f
                    continue
            # if we make it this far, we have files that we are ignoring
            ignored_files.append("%s/%s" % (s.name(), f.name()))
    # finally, process the last stream
    print "Processing last stream"
    one_task_per_gvcf_group_in_stream_combined_inputs(stream_name, gvcf_by_group, gvcf_indices, interval_list_by_group, if_sequence, ref_input, create_task_func=create_task_func)

    # report on any ignored files
    if len(ignored_files) > 0:
        print "WARNING: ignored non-matching files in inputs_collection: %s" % (' '.join(ignored_files))
        # TODO: could use `setmedian` from https://github.com/ztane/python-Levenshtein
        # to print most representative "median" filename (i.e. skipped 15 files like median), then compare the
        # rest of the files to that median (perhaps with `ratio`)

    if and_end_task:
        print "Ending task %s successfully" % if_sequence
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':True}
                                         ).execute()
        exit(0)

def one_task_per_interval(interval_count, validate_task_output,
                          if_sequence=0, and_end_task=True,
                          reuse_tasks=True,
                          interval_list_param="interval_list",
                          oldest_git_commit_to_reuse='6ca726fc265f9e55765bf1fdf71b86285b8a0ff2',
                          task_key_params=['name', 'inputs', 'interval', 'ref'],
                          script=arvados.current_job()['script']):
    """
    Queue one task for each of interval_count intervals, splitting
    the genome chunk (described by the .interval_list file) evenly.

    Each new task will have an "inputs" parameter: a manifest
    containing a set of one or more gVCF files and its corresponding
    index.

    Each new task will also have a "ref" parameter: a manifest
    containing the reference files to use.

    Note that all gVCFs not matching the group_by_regex are ignored.

    if_sequence and and_end_task arguments have the same significance
    as in arvados.job_setup.one_task_per_input_file().
    """
    if if_sequence != arvados.current_task()['sequence']:
        return

    interval_list_file = gatk_helper.mount_single_gatk_interval_list_input(interval_list_param=interval_list_param)

    interval_reader = open(interval_list_file, mode="r")

    lines = interval_reader.readlines()
    intervals_sn_start_end = dict()
    interval_keys = []
    total_len = 0
    for line in lines:
        if line[0] == '@':
            # skip all lines starting with '@'
            continue
        fields = line.split("\t")
        if len(fields) != 5:
            raise errors.InvalidArgumentError("interval_list %s has invalid line [%s] - expected 5 fields but got %s" % (interval_list_file, line, len(fields)))
        sn = fields[0]
        start = int(fields[1])
        end = int(fields[2])
        length = int(end) - int(start) + 1
        total_len += int(length)
        interval_key = "%s:%s-%s" % (sn, start, end)
        intervals_sn_start_end[interval_key] = (sn, start, end)
        interval_keys.append(interval_key)

    print "Total chunk length is %s" % total_len
    interval_len = int(total_len / interval_count)
    intervals = []
    print "Splitting chunk into %s intervals of size ~%s" % (interval_count, interval_len)
    for interval_i in range(0, interval_count):
        interval_num = interval_i + 1
        intervals_count = 0
        remaining_len = interval_len
        interval = []
        while len(interval_keys) > 0:
            interval_key = interval_keys.pop(0)
            if not intervals_sn_start_end.has_key(interval_key):
                raise errors.ValueError("intervals_sn_start_end missing entry for interval_key [%s]" % interval_key)
            sn, start, end = intervals_sn_start_end[interval_key]
            if (end-start+1) > remaining_len:
                # not enough space for the whole sq, split it
                real_end = end
                end = remaining_len + start - 1
                assert((end-start+1) <= remaining_len)
                intervals_sn_start_end[interval_key] = (sn, end+1, real_end)
                interval_keys.insert(0, interval_key)
            interval.append("%s:%s-%s" % (sn, start, end))
            remaining_len -= (end-start+1)
            intervals_count += 1
            if remaining_len <= 0:
                break
        if intervals_count > 0:
            intervals.append(interval)
        else:
            print "WARNING: skipping empty intervals for %s" % interval_input_name
    print "Have %s intervals" % (len(intervals))

    if reuse_tasks:
        # get candidates for task reuse
        job_filters = [
            ['script', '=', script],
            ['repository', '=', arvados.current_job()['repository']],
            ['script_version', 'in git', oldest_git_commit_to_reuse],
            ['docker_image_locator', 'in docker', arvados.current_job()['docker_image_locator']],
        ]
        reusable_tasks = get_reusable_tasks(if_sequence + 1, task_key_params, job_filters)
        print "Have %s potentially reusable tasks" % (len(reusable_tasks))

    for interval in intervals:
        interval_str = ' '.join(interval)
        print "Creating task to process interval: [%s]" % interval_str
        new_task_params = arvados.current_task()['parameters']
        new_task_params['interval'] = interval_str
        if reuse_tasks:
            task = create_or_reuse_task(if_sequence + 1, new_task_params, reusable_tasks, task_key_params, validate_task_output)
        else:
            task = create_task(if_sequence + 1, new_task_params)

    if and_end_task:
        print "Ending task %s successfully" % if_sequence
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':True}
                                         ).execute()
        exit(0)

def execute_list_all(api_obj, **kwargs):
    batch_size=kwargs.pop("batch_size", 25000)
    offset=kwargs.pop("offset", 0)
    num_retries=kwargs.pop("num_retries", 3)
    limit=kwargs.pop("limit", None)
    if limit and limit < batch_size:
        batch_size = limit
    first_batch = api_obj.list(limit=batch_size, offset=offset, **kwargs).execute(num_retries=num_retries)
    def _gen_items(batch_results, batch_size, offset, num_retries, limit):
        count = 0
        batch_offset = offset
        items = batch_results['items']
        while True:
            for item in items:
                count += 1
                yield item
                if limit and count >= limit:
                    break
            print "Batch had %s items, %s items retrieved so far (batch_offset at %s out of %s)" % (len(items), count, batch_offset, batch_results['items_available'])
            batch_offset = batch_offset + len(items)
            batch_results = api_obj.list(limit=batch_size, offset=batch_offset, **kwargs).execute(num_retries=num_retries)
            if len(batch_results['items']) > 0:
                items = batch_results['items']
            else:
                if count < batch_results['items_available']:
                    print "WARNING: received no items in batch but count still less than items_available (batch_size %s, batch_offset %s): %s" % (batch_size, batch_offset, batch_results)
                print "All batches complete, retrieved %s items in total" % (count)
                break
    results = first_batch.copy()
    results['items'] = _gen_items(first_batch, batch_size, offset, num_retries, limit)
    return results

def get_jobs_for_task_reuse(job_filters):
    print "Querying API server for jobs matching filters %s" % (json.dumps(job_filters))
    jobs = execute_list_all(arvados.api().jobs(), filters=job_filters, distinct=True, select=['uuid'])
    return jobs


def create_or_reuse_task_from_jobs(sequence, parameters, reusable_task_job_uuids, task_key_params, validate_task_output):
    reusable_tasks = {}
    task_filters = [
        ['sequence', '=', str(sequence)],
        ['success', '=', 'True'],
    ]
    # create horrible 'like' filters to match each task parameter (assumes they are stored as YAML)
    for param in task_key_params:
        param_value = parameters[param]
        param_value = param_value.replace('%','\%')
        param_value = param_value.replace('_','\_')
        param_like = "%s%s: %s%s" % ('%', param, param_value, '%')
        task_filters.append(["parameters","like",param_like])

    print "Querying API server for tasks matching filters %s" % (json.dumps(task_filters))
    tasks = execute_list_all(arvados.api().job_tasks(),
                             distinct=True,
                             select=['uuid', 'job_uuid', 'output',
                                     'parameters', 'success',
                                     'progress', 'started_at',
                                     'finished_at'],
                            filters=task_filters)
    if tasks['items_available'] > 0:
        print "Have %s potential reusable task outputs" % ( tasks['items_available'] )
        for task in tasks['items']:
            # verify that this task belonged to one of the reusable_task_job_uuids
            ct_index = tuple([task['parameters'][index_param] for index_param in task_key_params])
            if task['job_uuid'] not in reusable_task_job_uuids:
                print "Have task with task key %s from job uuid %s but it does not belong to one of the %s reusable_task_job_uuids" % (list(ct_index), task['job_uuid'], len(reusable_task_job_uuids))
                continue
            if ct_index in reusable_tasks:
                # we have already seen a task with these parameters (from another job?) - verify they have the same output
                if reusable_tasks[ct_index]['output'] != task['output']:
                    print "WARNING: found two existing candidate JobTasks for parameters %s and the output does not match! (using JobTask %s from Job %s with output %s, but JobTask %s from Job %s had output %s)" % (ct_index, reusable_tasks[ct_index]['uuid'], reusable_tasks[ct_index]['job_uuid'], reusable_tasks[ct_index]['output'], task['uuid'], task['job_uuid'], task['output'])
            else:
                # store the candidate task in reusable_tasks, indexed on the tuple of params specified in task_key_params
                reusable_tasks[ct_index] = task
    else:
        print "No potential reusable task outputs found"
    return create_or_reuse_task(sequence, parameters, reusable_tasks, task_key_params, validate_task_output)

def get_reusable_tasks(sequence, task_key_params, job_filters):
    reusable_tasks = {}
    jobs = get_jobs_for_task_reuse(job_filters)
    print "Found %s similar previous jobs, checking them for reusable tasks" % (jobs['items_available'])
    task_filters = [
        ['job_uuid', 'in', [job['uuid'] for job in jobs['items']]],
        ['sequence', '=', str(sequence)],
        ['success', '=', 'True'],
    ]
    #print "Querying API server for tasks matching filters %s" % (json.dumps(task_filters))
    tasks = execute_list_all(arvados.api().job_tasks(),
                             distinct=True,
                             select=['uuid', 'job_uuid', 'output',
                                     'parameters', 'success',
                                     'progress', 'started_at',
                                     'finished_at'],
                            filters=task_filters)
    if tasks['items_available'] > 0:
        print "Have %s potential reusable task outputs" % ( tasks['items_available'] )
        for task in tasks['items']:
            have_all_params=True
            for index_param in task_key_params:
                if index_param not in task['parameters']:
                    print "WARNING: missing task key param %s in JobTask %s from Job %s (have parameters: %s)" % (index_param, task['uuid'], task['job_uuid'], ', '.join(task['parameters'].keys()))
                    have_all_params=False
            if have_all_params:
                ct_index = tuple([task['parameters'][index_param] for index_param in task_key_params])
                if ct_index in reusable_tasks:
                    # we have already seen a task with these parameters (from another job?) - verify they have the same output
                    if reusable_tasks[ct_index]['output'] != task['output']:
                        print "WARNING: found two existing candidate JobTasks for parameters %s and the output does not match! (using JobTask %s from Job %s with output %s, but JobTask %s from Job %s had output %s)" % (ct_index, reusable_tasks[ct_index]['uuid'], reusable_tasks[ct_index]['job_uuid'], reusable_tasks[ct_index]['output'], task['uuid'], task['job_uuid'], task['output'])
                else:
                    # store the candidate task in reusable_tasks, indexed on the tuple of params specified in task_key_params
                    reusable_tasks[ct_index] = task
    return reusable_tasks


def create_or_reuse_task(sequence, parameters, reusable_tasks, task_key_params, validate_task_output):
    new_task_attrs = {
            'job_uuid': arvados.current_job()['uuid'],
            'created_by_job_task_uuid': arvados.current_task()['uuid'],
            'sequence': sequence,
            'parameters': parameters
            }
    # See if there is a task in reusable_tasks that can be reused
    ct_index = tuple([parameters[index_param] for index_param in task_key_params])
    if len(reusable_tasks) == 0:
        print "No reusable tasks were available"
    elif ct_index in reusable_tasks:
        # have a task from which to reuse the output, prepare to create a new, but already finished, task with that output
        reuse_task = reusable_tasks[ct_index]
        if validate_task_output(reuse_task['output']):
            print "Found existing JobTask %s from Job %s. Will use output %s from that JobTask instead of re-running it." % (reuse_task['uuid'], reuse_task['job_uuid'], reuse_task['output'])
            # remove task from reusable_tasks as it won't be used more than once
            del reusable_tasks[ct_index]
            # copy relevant attrs from reuse_task so that the new tasks start already finished
            for attr in ['success', 'output', 'progress', 'started_at', 'finished_at', 'parameters']:
                new_task_attrs[attr] = reuse_task[attr]
            # crunch seems to ignore the fact that the job says it is done and queue it anyway
            # signal ourselves to just immediately exit successfully when we are run
            new_task_attrs['parameters']['reuse_job_task'] = reuse_task['uuid']
        else:
            print "Output %s for potential task reuse did not validate" % (reuse_task['output'])
    else:
        print "No reusable JobTask matched key parameters %s" % (list(ct_index))

    # Create the "new" task (may be new work or may be already finished work)
    new_task = arvados.api().job_tasks().create(body=new_task_attrs).execute()
    if not new_task:
        raise errors.APIError("Attempt to create new job_task failed: [%s]" % new_task_attrs)
    return new_task

def prepare_out_dir():
    # Will write to out_dir, make sure it is empty
    out_dir = os.path.join(arvados.current_task().tmpdir, 'out')
    if os.path.exists(out_dir):
        old_out_dir = out_dir + ".old"
        print "Moving out_dir %s out of the way (to %s)" % (out_dir, old_out_dir)
        try:
            os.rename(out_dir, old_out_dir)
        except:
            raise
    try:
        os.mkdir(out_dir)
        os.chdir(out_dir)
    except:
        raise
    return out_dir


if __name__ == '__main__':
    print "This module is not intended to be executed as a script"
    sys.exit(1)
