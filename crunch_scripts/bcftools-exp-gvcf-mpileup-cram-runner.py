#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess
import jinja2

RUNNER_CONFIG_TEMPLATE = "/etc/runner/gvcf.mpileup.conf.j2"

# TODO: make genome_chunks a parameter
genome_chunks = 1

# TODO: make skip_sq_sn_regex a paramter
#skip_sq_sn_regex = '_decoy$'
skip_sq_sn_regex = '([_-]|EBV)'
skip_sq_sn_r = re.compile(skip_sq_sn_regex)

class InvalidArgumentError(Exception):
    pass

class FileAccessError(Exception):
    pass

def one_task_per_cram_file(if_sequence=0, and_end_task=True):
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

    # Ensure we have a .fa reference file with corresponding .fai index and .dict
    reference_coll = arvados.current_job()['script_parameters']['reference_collection']
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

    # Create a portable data hash for the ref_input manifest
    try:
        r = arvados.api().collections().create(body={"manifest_text": ref_input}).execute()
        ref_input_pdh = r["portable_data_hash"]
    except:
        raise 

    # Load the dict data
    interval_header = ""
    dict_lines = dict_reader.readlines()
    dict_header = dict_lines.pop(0)
    if re.search(r'^@HD', dict_header) is None:
        raise InvalidArgumentError("Dict file in reference collection does not have correct header: [%s]" % dict_header)
    interval_header += dict_header
    print "Dict header is %s" % dict_header
    sn_intervals = dict()
    sns = []
    total_len = 0
    for sq in dict_lines:
        if re.search(r'^@SQ', sq) is None:
            raise InvalidArgumentError("Dict file contains malformed SQ line: [%s]" % sq)
        interval_header += sq
        sn = None
        ln = None
        for tagval in sq.split("\t"):
            tv = tagval.split(":", 1)
            if tv[0] == "SN":
                sn = tv[1]
            if tv[0] == "LN":
                ln = tv[1]
            if sn and ln:
                break
        if not (sn and ln):
            raise InvalidArgumentError("Dict file SQ entry missing required SN and/or LN parameters: [%s]" % sq)
        assert(sn and ln)
        if sn_intervals.has_key(sn):
            raise InvalidArgumentError("Dict file has duplicate SQ entry for SN %s: [%s]" % (sn, sq))
        if skip_sq_sn_r.search(sn):
            next
        sn_intervals[sn] = (1, int(ln))
        sns.append(sn)
        total_len += int(ln)

    # Chunk the genome into genome_chunks equally sized pieces and create intervals files
    print "Total genome length is %s" % total_len
    chunk_len = int(total_len / genome_chunks)
    chunk_input_pdh_name = []
    print "Chunking genome into %s chunks of size ~%s" % (genome_chunks, chunk_len)
    for chunk_i in range(0, genome_chunks):
        chunk_num = chunk_i + 1
        chunk_intervals_count = 0
        chunk_input_name = dict_reader.name() + (".%s_of_%s.region_list.txt" % (chunk_num, genome_chunks))
        print "Creating interval file for chunk %s" % chunk_num
        chunk_c = arvados.collection.CollectionWriter(num_retries=3)
        chunk_c.start_new_file(newfilename=chunk_input_name)
        # chunk_c.write(interval_header)
        remaining_len = chunk_len
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
            #interval = "%s\t%s\t%s\t+\t%s\n" % (sn, start, end, "interval_%s_of_%s_%s" % (chunk_num, genome_chunks, sn))
            interval = "%s\t%s\t%s\n" % (sn, start, end)
            remaining_len -= (end-start+1)
            chunk_c.write(interval)
            chunk_intervals_count += 1
            if remaining_len <= 0:
                break
        if chunk_intervals_count > 0:
            chunk_input_pdh = chunk_c.finish()
            print "Chunk intervals file %s saved as %s" % (chunk_input_name, chunk_input_pdh)
            chunk_input_pdh_name.append((chunk_input_pdh, chunk_input_name))
        else:
            print "WARNING: skipping empty intervals for %s" % chunk_input_name
    print "Have %s chunk collections: [%s]" % (len(chunk_input_pdh_name), ' '.join([x[0] for x in chunk_input_pdh_name]))

    # prepare CRAM input collections
    job_input = arvados.current_job()['script_parameters']['inputs_collection']
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
            raise InvalidArgumentError("No correponding CRAI file found for CRAM file %s" % f_name)

        # Create a portable data hash for the task's subcollection
        try:
            r = arvados.api().collections().create(body={"manifest_text": task_input}).execute()
            task_input_pdh = r["portable_data_hash"]
        except:
            raise 
        
        for chunk_input_pdh, chunk_input_name in chunk_input_pdh_name:
            # Create task for each CRAM / chunk
            print "Creating new task to process %s with chunk interval %s " % (f_name, chunk_input_name)
            new_task_attrs = {
                'job_uuid': arvados.current_job()['uuid'],
                'created_by_job_task_uuid': arvados.current_task()['uuid'],
                'sequence': if_sequence + 1,
                'parameters': {
                    'input': task_input_pdh,
                    'ref': ref_input_pdh,
                    'chunk': chunk_input_pdh
                    }
                }
            arvados.api().job_tasks().create(body=new_task_attrs).execute()

    if and_end_task:
        print "Ending task 0 successfully"
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':True}
                                         ).execute()
        exit(0)


def main():

    this_job = arvados.current_job()

    # Setup sub tasks 1-N (and terminate if this is task 0)
    one_task_per_cram_file(if_sequence=0, and_end_task=True)

    # Get object representing the current task
    this_task = arvados.current_task()

    # We will never reach this point if we are in the 0th task
    assert(this_task['sequence'] != 0)

    # Get reference FASTA
    ref_file = None
    print "Mounting reference FASTA collection"
    ref_dir = arvados.get_task_param_mount('ref')

    for f in arvados.util.listdir_recursive(ref_dir):
        if re.search(r'\.fa$', f):
            ref_file = os.path.join(ref_dir, f)
    if ref_file is None:
        raise InvalidArgumentError("No reference fasta found in reference collection.")
    # Ensure we can read the reference file
    if not os.access(ref_file, os.R_OK):
        raise FileAccessError("reference FASTA file not readable: %s" % ref_file)
    # TODO: could check readability of .fai and .dict as well?

    # Get genome chunk intervals file
    chunk_file = None
    print "Mounting chunk collection"
    chunk_dir = arvados.get_task_param_mount('chunk')

    for f in arvados.util.listdir_recursive(chunk_dir):
        if re.search(r'\.region_list.txt$', f):
            chunk_file = os.path.join(chunk_dir, f)
    if chunk_file is None:
        raise InvalidArgumentError("No chunk intervals file found in chunk collection.")
    # Ensure we can read the chunk file
    if not os.access(chunk_file, os.R_OK):
        raise FileAccessError("Chunk intervals file not readable: %s" % chunk_file)

    # Get single CRAM file for this task 
    input_dir = None
    print "Mounting task input collection"
    input_dir = arvados.get_task_param_mount('input')

    input_cram_files = []
    for f in arvados.util.listdir_recursive(input_dir):
        if re.search(r'\.cram$', f):
            stream_name, input_file_name = os.path.split(f)
            input_cram_files += [os.path.join(input_dir, f)]
    if len(input_cram_files) != 1:
        raise InvalidArgumentError("Expected exactly one cram file per task.")

    # There is only one CRAM file
    cram_file = input_cram_files[0]

    # Ensure we can read the CRAM file
    if not os.access(cram_file, os.R_OK):
        raise FileAccessError("CRAM file not readable: %s" % cram_file)

    # Ensure we have corresponding CRAI index and can read it as well
    cram_file_base, cram_file_ext = os.path.splitext(cram_file)
    assert(cram_file_ext == ".cram")
    crai_file = cram_file_base + ".crai"
    if not os.access(crai_file, os.R_OK):
        crai_file = cram_file_base + ".cram.crai"
        if not os.access(crai_file, os.R_OK):
            raise FileAccessError("No readable CRAM index file for CRAM file: %s" % cram_file)

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
#    out_file = os.path.join(out_dir, os.path.basename(cram_file_base) + "." + os.path.basename(chunk_file) + ".g.vcf.gz")
    config_file = os.path.join(arvados.current_task().tmpdir, "mpileup.conf")
    lock_file = os.path.join(arvados.current_task().tmpdir, "run-bt-mpileup.lock")

    if not os.path.exists(RUNNER_CONFIG_TEMPLATE):
        raise FileAccessError("No runner configuration template at %s" % RUNNER_CONFIG_TEMPLATE)
    # generate config
    runner_config_text = jinja2.Environment(loader=jinja2.FileSystemLoader("/")).get_template(RUNNER_CONFIG_TEMPLATE).render( 
        fasta_reference = ref_file, 
        input_cram = cram_file, 
        regions = chunk_file )
    with open(config_file, "wb") as fh:
        fh.write(runner_config_text)
    # report configuration
    print "Generated runner config to %s:\n%s" % (config_file, runner_config_text)

    # Call run-bt-mpileup
    runner_p = subprocess.Popen(
        [
            "run-bt-mpileup", 
            "+config", config_file, 
            "+js", "mpm",
            "+loop", "5",
            "+lock", lock_file,
            "-o", out_dir
            ], 
        stdin=None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        close_fds=True,
        shell=False)

    while runner_p.poll() is None:
        line = runner_p.stdout.readline()
        # only print '#### unfinished' lines or things that are errors or warnings
        if re.search(r'\d+\s+unfinished', line) or re.search(r'(FATAL|ERROR|WARNING)', line, flags=re.IGNORECASE):
            print "RUNNER: %s" % line.rstrip()

    runner_exit = runner_p.wait()
    if runner_exit != 0:
        print "WARNING: runner exited with exit code %s" % runner_exit

    # clean up out_dir
    try:
        os.remove(os.path.join(out_dir, "run-bt-mpileup.lock"))
        os.remove(os.path.join(out_dir, "mpileup.conf"))
        os.remove(os.path.join(out_dir, "cleaned-job-outputs.tgz"))
    except:
        print "WARNING: could not remove some output files!"
        pass

    out_bcf = os.path.join(out_dir, os.path.basename(cram_file_base) + "." + os.path.basename(chunk_file) + ".bcf")
    try:
        os.rename(os.path.join(out_dir, "all.bcf"), out_bcf)
        os.rename(os.path.join(out_dir, "all.bcf.csi"), out_bcf + ".csi")
        os.rename(os.path.join(out_dir, "all.bcf.filt.vchk"), out_bcf + ".filt.vchk")
        os.rename(os.path.join(out_dir, "all.bcf.vchk"), out_bcf + ".vchk")
    except:
        print "WARNING: could not rename some output files!"
        pass

    # Write a new collection as output
    out = arvados.CollectionWriter()

    # Write out_dir to keep
    out.write_directory_tree(out_dir, stream_name)

    # Commit the output to Keep.
    output_locator = out.finish()

    # Use the resulting locator as the output for this task.
    this_task.set_output(output_locator)

    # Done!

if __name__ == '__main__':
    main()
