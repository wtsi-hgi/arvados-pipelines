#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re

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
        crai_f = crai.get((s_name, re.sub(r'cram$', 'crai', f_name)), None)
        task_input = cram_f.as_manifest()
        if crai_f:
            task_input += crai_f.as_manifest()
        new_task_attrs = {
            'job_uuid': arvados.current_job()['uuid'],
            'created_by_job_task_uuid': arvados.current_task()['uuid'],
            'sequence': if_sequence + 1,
            'parameters': {
                'input': task_input
                }
            }
        arvados.api().job_tasks().create(body=new_task_attrs).execute()
    if and_end_task:
        arvados.api().job_tasks().update(uuid=arvados.current_task()['uuid'],
                                         body={'success':True}
                                         ).execute()
        exit(0)


# Ensure we have a .fa reference file with corresponding .fai index and .dict
# see: http://gatkforums.broadinstitute.org/discussion/1601/how-can-i-prepare-a-fasta-file-to-use-as-reference
reference_coll = arvados.current_job()['script_parameters']['reference_collection']
rcr = arvados.CollectionReader(reference_coll)
ref_fasta = {}
ref_fai = {}
ref_dict = {}
ref_input = None
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
        break
if ref_input is None:
    raise InvalidArgumentError("Expected a reference fasta with fai and dict in reference_collection. Found [%s]" % ' '.join(rf.name() for rf in rs.all_files()))

# Setup sub tasks 1-N (and terminate if this is task 0)
one_task_per_cram_file(if_sequence=0, and_end_task=True)

# Get object representing the current task
this_task = arvados.current_task()

# We will never reach this point if we are in the 0th task
assert(this_task['sequence'] != 0)

# Get tmpdir
tmpdir = this_task.tmpdir
print "Using tmpdir %s" % tmpdir

# Get reference FASTA
print "Getting reference FASTA from keep"
ref_file = None
ref_dir = arvados.util.collection_extract(
    collection = ref_input,
    path = os.path.join(tmpdir, 'ref'))
for f in arvados.util.listdir_recursive(ref_dir):
    if re.search(r'\.fa$', f):
        ref_file = os.path.join(ref_dir, f)
if ref_file is None:
    raise InvalidArgumentError("No reference fasta found in reference collection.")

# Ensure we can read the reference file
if not os.access(ref_file, os.R_OK):
    raise FileAccessError("reference FASTA file not readable: %s" % ref_file)
# TODO: could check readability of .fai and .dict as well?

# Get single CRAM file for this task 
print "Getting input CRAM from keep"
task_input = this_task['parameters']['input']
input_dir = arvados.util.collection_extract(
    collection = task_input,
    path = os.path.join(tmpdir, 'input'))
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
try:
    os.mkdir(out_dir)
    os.chdir(out_dir)
except:
    raise
out_file = os.path.join(out_dir, cram_file_base, ".vcf.gz")

# Call GATK HaplotypeCaller
arvados.util.run_command([
    "java", "-jar", "/gatk/GenomeAnalysisTK.jar", 
    "-T", "HaplotypeCaller", 
    "-R", ref_file,
    "-I", cram_file,
    "--emitRefConfidence", "GVCF", 
    "--variant_index_type", "LINEAR", 
    "--variant_index_parameter", "128000", 
    "-o", out_file
])

# Write a new collection as output
out = arvados.CollectionWriter()

# Write out_dir to keep
out.write_directory_tree(out_dir, stream_name)

# Commit the output to Keep.
output_locator = out.finish()

# Use the resulting locator as the output for this task.
this_task.set_output(output_locator)

# Done!
