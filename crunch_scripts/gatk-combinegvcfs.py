#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess

# TODO: make group_by_regex and max_gvcfs_to_combine parameters
group_by_regex = '[.](?P<group_by>[0-9]+_of_[0-9]+)[.]'
max_gvcfs_to_combine = 200
interval_count = 1

class InvalidArgumentError(Exception):
    pass

class FileAccessError(Exception):
    pass

class APIError(Exception):
    pass

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
        raise InvalidArgumentError("Expected a reference fasta with fai and dict in reference_collection. Found [%s]" % ' '.join(rf.name() for rf in rs.all_files()))
    if dict_reader is None:
        raise InvalidArgumentError("Could not find .dict file in reference_collection. Found [%s]" % ' '.join(rf.name() for rf in rs.all_files()))
    # Create and return a portable data hash for the ref_input manifest
    try:
        r = arvados.api().collections().create(body={"manifest_text": ref_input}).execute()
        ref_input_pdh = r["portable_data_hash"]
    except:
        raise 
    return ref_input_pdh

def one_task_per_group_and_per_n_gvcfs(group_by_regex, n, ref_input_pdh, 
                                       if_sequence=0, and_end_task=True):
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
        group.

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
    il_coll = arvados.current_job()['script_parameters']['interval_lists_collection']
    il_cr = arvados.CollectionReader(il_coll)
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
    job_input = arvados.current_job()['script_parameters']['inputs_collection']
    cr = arvados.CollectionReader(job_input)
    ignored_files = []
    for s in sorted(list(set(cr.all_streams())), key=lambda stream: stream.name()):
        # handle each stream separately
        stream_name = s.name()
        gvcf_by_group = {}
        gvcf_indices = {}
        print "Processing files in stream %s" % stream_name
        for f in s.all_files():
            if re.search(r'\.tbi$', f.name()):
                gvcf_indices[s.name(), f.name()] = f
                continue
            m = re.search(group_by_r, f.name())
            if m:
                group_name = m.group('group_by')
                gvcf_m = re.search(r'\.g\.vcf\.gz$', f.name())
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
                            raise InvalidArgumentError("Already have interval_list for group %s file %s/%s, but manifests are not identical!" % (group_name, s.name(), f.name()))
                    else: 
                        interval_list_by_group[group_name][s.name(), f.name()] = f
                    continue
            # if we make it this far, we have files that we are ignoring
            ignored_files.append("%s/%s" % (s.name(), f.name()))
        for group_name in gvcf_by_group.keys():
            print "Have %s gVCFs in group %s" % (len(gvcf_by_group[group_name]), group_name)
            # require interval_list for this group
            if group_name not in interval_list_by_group:
                raise InvalidArgumentError("Inputs collection did not contain interval_list for group %s" % group_name)
            interval_lists = interval_list_by_group[group_name].keys()
            if len(interval_lists) > 1:
                raise InvalidArgumentError("Inputs collection contained more than one interval_list for group %s: %s" % (group_name, ' '.join(interval_lists)))
            task_inputs_manifest = interval_list_by_group[group_name].get(interval_lists[0]).as_manifest()
            for ((s_name, gvcf_name), gvcf_f) in gvcf_by_group[group_name].items():
                task_inputs_manifest += gvcf_f.as_manifest()
                gvcf_index_f = gvcf_indices.get((s_name, re.sub(r'g.vcf.gz$', 'g.vcf.tbi', gvcf_name)), 
                                                gvcf_indices.get((s_name, re.sub(r'g.vcf.gz$', 'g.vcf.gz.tbi', gvcf_name)), 
                                                                 None))
                if gvcf_index_f:
                    task_inputs_manifest += gvcf_index_f.as_manifest()
                else:
                    # no index for gVCF - TODO: should this be an error or warning?
                    print "WARNING: No correponding .tbi index file found for gVCF file %s" % gvcf_name
                    #raise InvalidArgumentError("No correponding .tbi index file found for gVCF file %s" % gvcf_name)

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
        print "Creating new task to process %s" % name
        new_task_attrs = {
                'job_uuid': arvados.current_job()['uuid'],
                'created_by_job_task_uuid': arvados.current_task()['uuid'],
                'sequence': if_sequence + 1,
                'parameters': {
                    'inputs': task_inputs_pdh,
                    'ref': ref_input_pdh,
                    'name': name
                    }
                }
        arvados.api().job_tasks().create(body=new_task_attrs).execute()

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

def one_task_per_interval(interval_count,
                          reuse_tasks=True,
                          if_sequence=0, and_end_task=True):
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

    interval_list_file = mount_gatk_interval_list_input(inputs_param='inputs')

    interval_reader = open(interval_list_file, mode="r")

    lines = interval_reader.readlines()
    sn_intervals = dict()
    sns = []
    total_len = 0
    for line in lines:
        if line[0] == '@':
            # skip all lines starting with '@'
            continue
        fields = line.split("\t")
        if len(fields) != 5:
            raise InvalidArgumentError("interval_list %s has invalid line [%s] - expected 5 fields but got %s" % (interval_list_file, line, len(fields)))
        sn = fields[0]
        start = int(fields[1])
        end = int(fields[2])
        length = int(end) - int(start) + 1
        total_len += int(length)
        sn_intervals[sn] = (start, end)
        sns.append(sn)

    print "Total chunk length is %s" % total_len
    interval_len = int(total_len / interval_count)
    intervals = []
    print "Splitting chunk into %s intervals of size ~%s" % (interval_count, interval_len)
    for interval_i in range(0, interval_count):
        interval_num = interval_i + 1
        intervals_count = 0
        remaining_len = interval_len
        interval = []
        while len(sns) > 0:
            sn = sns.pop(0)
            if not sn_intervals.has_key(sn):
                raise ValueError("sn_intervals missing entry for sn [%s]" % sn)
            start, end = sn_intervals[sn]
            if (end-start+1) > remaining_len:
                # not enough space for the whole sq, split it
                real_end = end
                end = remaining_len + start - 1
                assert((end-start+1) <= remaining_len)
                sn_intervals[sn] = (end+1, real_end)
                sns.insert(0, sn)
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

    # get candidates for task reuse
    index_params = ['name', 'inputs', 'interval', 'ref']
    reusable_tasks = get_reusable_tasks(if_sequence + 1, index_params)

    for interval in intervals:
        interval_str = ' '.join(interval)
        print "Creating task to process interval: [%s]" % interval_str
        new_task_params = arvados.current_task()['parameters']
        new_task_params['interval'] = interval_str
        task = create_or_reuse_task(reusable_tasks, if_sequence + 1, new_task_params, index_params)
        
    if and_end_task:
        print "Ending task %s successfully" % if_sequence
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':True}
                                         ).execute()
        exit(0)

def get_reusable_tasks(sequence, index_params):
    reusable_tasks = {}
    job_filters=[
        ['script', '=', 'gatk-combinegvcfs.py'],
        ['repository','=',arvados.current_job()['repository']], 
        ['script_version', 'in git', '6ca726fc265f9e55765bf1fdf71b86285b8a0ff2'], 
        ['docker_image_locator', 'in docker', arvados.current_job()['docker_image_locator']], 
        ]
    jobs = arvados.api().jobs().list(filters=job_filters).execute()
    for job in jobs['items']:
        tasks = arvados.api().job_tasks().list(limit=100000,
                                               filters=[
                ['job_uuid', '=', job['uuid']],
                ['sequence', '=', str(sequence)],
                ['success', '=', 'True'],
                ]).execute()
        if tasks['items_available'] > 0:
            print "Have %s potential reusable task outputs from job %s" % ( tasks['items_available'], job['uuid'] )
            for task in tasks['items']:
                ct_index = tuple([task['parameters'][index_param] for index_param in index_params])
                if ct_index in reusable_tasks:
                    # we have already seen a task with these parameters (from another job?) - verify they have the same output
                    if reusable_tasks[ct_index]['output'] != task['output']:
                        print "WARNING: found two existing candidate JobTasks for parameters %s and the output does not match! (using JobTask %s from Job %s with output %s, but JobTask %s from Job %s had output %s)" % (ct_index, reusable_tasks[ct_index]['uuid'], reusable_tasks[ct_index]['job_uuid'], reusable_tasks[ct_index]['output'], task['uuid'], task['job_uuid'], task['output'])
                else:
                    # store the candidate task in reusable_tasks, indexed on the tuple of params specified in index_params
                    reusable_tasks[ct_index] = task
    return reusable_tasks

def create_or_reuse_task(reusable_tasks, sequence, parameters, index_params):
    new_task_attrs = {
            'job_uuid': arvados.current_job()['uuid'],
            'created_by_job_task_uuid': arvados.current_task()['uuid'],
            'sequence': sequence,
            'parameters': parameters
            }
    # See if there is a task in reusable_tasks that can be reused
    ct_index = tuple([parameters[index_param] for index_param in index_params])
    if ct_index in reusable_tasks:
        # have a task from which to reuse the output, prepare to create a new, but already finished, task with that output
        reuse_task = reusable_tasks[ct_index]
        print "Found existing JobTask %s from Job %s. Will use output %s from that JobTask instead of re-running it." % (reuse_task['uuid'], reuse_task['job_uuid'], reuse_task['output'])
        # remove task from reusable_tasks as it won't be used more than once
        del reusable_tasks[ct_index]
        # copy relevant attrs from reuse_task so that the new tasks start already finished
        for attr in ['success', 'output', 'progress', 'started_at', 'finished_at', 'parameters', ]:
            new_task_attrs[attr] = reuse_task[attr]
        # crunch seems to ignore the fact that the job says it is done and queue it anyway
        # signal ourselves to just immediately exit successfully when we are run
        new_task_attrs['parameters']['reuse_job_task'] = reuse_task['uuid']
    # Create the "new" task (may be new work or may be already finished work)
    new_task = arvados.api().job_tasks().create(body=new_task_attrs).execute()
    if not new_task:
        raise APIError("Attempt to create new job_task failed: [%s]" % new_task_attrs)
    return new_task

def mount_gatk_reference(ref_param="ref"):
    # Get reference FASTA
    print "Mounting reference FASTA collection"
    ref_dir = arvados.get_task_param_mount(ref_param)

    # Sanity check reference FASTA
    for f in arvados.util.listdir_recursive(ref_dir):
        if re.search(r'\.fa$', f):
            ref_file = os.path.join(ref_dir, f)
    if ref_file is None:
        raise InvalidArgumentError("No reference fasta found in reference collection.")
    # Ensure we can read the reference file
    if not os.access(ref_file, os.R_OK):
        raise FileAccessError("reference FASTA file not readable: %s" % ref_file)
    # TODO: could check readability of .fai and .dict as well?
    return ref_file

def mount_gatk_gvcf_inputs(inputs_param="inputs"):
    # Get input gVCFs for this task
    print "Mounting task input collection"
    inputs_dir = arvados.get_task_param_mount('inputs')

    # Sanity check input gVCFs    
    input_gvcf_files = []
    for f in arvados.util.listdir_recursive(inputs_dir):
        if re.search(r'\.g\.vcf\.gz$', f):
            input_gvcf_files.append(os.path.join(inputs_dir, f))
        elif re.search(r'\.tbi$', f):
            pass
        elif re.search(r'\.interval_list$', f):
            pass
        else:
            print "WARNING: collection contains unexpected file %s" % f
    if len(input_gvcf_files) == 0:
        raise InvalidArgumentError("Expected one or more .g.vcf.gz files in collection (found 0 while recursively searching %s)" % inputs_dir)

    # Ensure we can read the gVCF files and that they each have an index
    for gvcf_file in input_gvcf_files:
        if not os.access(gvcf_file, os.R_OK):
            raise FileAccessError("gVCF file not readable: %s" % gvcf_file)

        # Ensure we have corresponding .tbi index and can read it as well
        (gvcf_file_base, gvcf_file_ext) = os.path.splitext(gvcf_file)
        assert(gvcf_file_ext == ".gz")
        tbi_file = gvcf_file_base + ".gz.tbi"
        if not os.access(tbi_file, os.R_OK):
            tbi_file = gvcf_file_base + ".tbi"
            if not os.access(tbi_file, os.R_OK):
                raise FileAccessError("No readable gVCF index file for gVCF file: %s" % gvcf_file)
    return input_gvcf_files

def mount_gatk_interval_list_input(inputs_param="inputs"):
    # Get interval_list for this task
    print "Mounting task input collection to get interval_list"
    inputs_dir = arvados.get_task_param_mount('inputs')

    # Sanity check input interval_list (there can be only one)
    input_interval_lists = []
    for f in arvados.util.listdir_recursive(inputs_dir):
        if re.search(r'\.interval_list$', f):
            input_interval_lists.append(os.path.join(inputs_dir, f))
    if len(input_interval_lists) != 1:
        raise InvalidArgumentError("Expected exactly one interval_list in inputs collection (found %s)" % len(input_interval_lists))

    assert(len(input_interval_lists) == 1)
    interval_list_file = input_interval_lists[0]

    if not os.access(interval_list_file, os.R_OK):
        raise FileAccessError("interval_list file not readable: %s" % interval_list_file)

    return interval_list_file

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

def gatk_combine_gvcfs(ref_file, gvcf_files, out_path, extra_args=[]):
    print "gatk_combine_gvcfs called with ref_file=[%s] gvcf_files=[%s] out_path=[%s] extra_args=[%s]" % (ref_file, ' '.join(gvcf_files), out_path, ' '.join(extra_args))
    # Call GATK CombineGVCFs
    gatk_args = [
            "java", "-d64", "-Xmx5g", "-jar", "/gatk/GenomeAnalysisTK.jar", 
            "-T", "CombineGVCFs", 
            "-R", ref_file]
    for gvcf_file in gvcf_files:
        gatk_args.extend(["--variant", gvcf_file])
    gatk_args.extend([
        "-o", out_path
    ])
    if extra_args:
        gatk_args.extend(extra_args)
    print "Calling GATK: %s" % gatk_args
    gatk_p = subprocess.Popen(
        gatk_args,
        stdin=None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        close_fds=True,
        shell=False)

    gatk_line_num = 0
    while gatk_p.poll() is None:
        line = gatk_p.stdout.readline()
        gatk_line_num += 1
        if gatk_line_num <= 300:
            print "GATK: %s" % line.rstrip()
        elif re.search(r'(FATAL|ERROR|ProgressMeter)', line):
            print "GATK: %s" % line.rstrip()

    gatk_exit = gatk_p.wait()
    return gatk_exit

def main():
    ################################################################################
    # Phase I: Check inputs and setup sub tasks 1-N to process group(s) based on 
    #          applying the capturing group named "group_by" in group_by_regex.
    #          (and terminate if this is task 0) 
    ################################################################################
    ref_input_pdh = prepare_gatk_reference_collection(reference_coll=arvados.current_job()['script_parameters']['reference_collection'])
    one_task_per_group_and_per_n_gvcfs(group_by_regex, max_gvcfs_to_combine, 
                                       ref_input_pdh, 
                                       if_sequence=0, and_end_task=True)

    # We will never reach this point if we are in the 0th task sequence
    assert(arvados.current_task()['sequence'] > 0)

    ################################################################################
    # Phase II: Read interval_list and split into additional intervals
    ################################################################################
    one_task_per_interval(interval_count,
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
    ref_file = mount_gatk_reference(ref_param="ref")
    gvcf_files = mount_gatk_gvcf_inputs(inputs_param="inputs")
    out_dir = prepare_out_dir()
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
            raise InvalidArgumentError("Output file name is too long, cannot continue: %s" % out_file)

    # CombineGVCFs! 
    gatk_exit = gatk_combine_gvcfs(ref_file, gvcf_files, os.path.join(out_dir, out_file), extra_args=intervals)

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
