import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

# Wraps GATK such that the specified output options are
# redirected to a temporary directory (in TMPDIR) and
# then copies them into the actual output paths after
# GATK has completed.
#
# Use case: workaround for Arvados local_output_dir
# using massive amounts of memory at the end of run.
# See: https://dev.arvados.org/issues/13100

output_argument_names_json = sys.argv[1]
extra_java_args_json = sys.argv[2]
gatk_command = sys.argv[3]
new_arguments = sys.argv[4:]

tmp2output = dict()
tmpdirs = list()

output_argument_names = json.loads(output_argument_names_json)
if not isinstance(output_argument_names, list):
    raise Exception("ERROR: first argument to gatk-tmpdir-output-wrapper.py should be a JSON string representing a list of output arguments. Have: '%s'" % (output_argument_names_json))

extra_java_args = json.loads(extra_java_args_json)
if not isinstance(output_argument_names, list):
    raise Exception("ERROR: second argument to gatk-tmpdir-output-wrapper.py should be a JSON string representing a list of extra java args. Have: '%s'" % (extra_java_json))

for output_argument_name in output_argument_names:
    argument_index = new_arguments.index(output_argument_name) + 1
    output_arg = new_arguments[argument_index]
    tmp_dir = tempfile.mkdtemp()
    print("gatk-tmpdir-output-wrapper.py: created temporary directory '%s' for output from GATK argument '%s'" % (tmp_dir, output_argument_name))
    tmpdirs.append(tmp_dir)
    m = re.search(r'^(?P<scheme>\w+://)?(?P<path>.*)$', output_arg)
    if m:
        output_scheme = m.group('scheme') or ""
        output_path = m.group('path')
    else:
        output_scheme = ""
        output_path = output_arg
    if os.path.isabs(output_path):
        tmp_path = os.path.join(tmp_dir, output_path[1:])
    else:
        tmp_path = os.path.join(tmp_dir, output_path)
    tmp_arg = output_scheme + tmp_path
    new_arguments[argument_index] = tmp_arg
    tmp2output[tmp_path] = output_path
    print("gatk-tmpdir-output-wrapper.py: redirected output for GATK argument '%s' from '%s' to '%s'" % (output_argument_name, output_arg, tmp_arg), file=sys.stderr)
    
gatk_command_args = ["java", "-d64"] + extra_java_args + ["-jar", "/gatk/gatk.jar", gatk_command] + new_arguments

# run GATK!
print('gatk-tmpdir-output-wrapper.py: running GATK: `%s`' % (' '.join([('"%s"' % arg) for arg in gatk_command_args])), file=sys.stderr)
gatk_exit_code = subprocess.run(gatk_command_args).returncode
print('gatk-tmpdir-output-wrapper.py: GATK exited with status %s' % (gatk_exit_code), file=sys.stderr)

# copy tmpdir outputs to output dirs
for tmp_path in tmp2output.keys():
    output_path = tmp2output[tmp_path]
    print("gatk-tmpdir-output-wrapper.py: copying output from tmp_path '%s' to output_path '%s'" % (tmp_path, output_path), file=sys.stderr)
    try:
        if os.path.isdir(tmp_path):
            shutil.copytree(tmp_path, output_path)
        elif os.path.isfile(tmp_path):
            shutil.copy(tmp_path, output_path)
        else:
            raise Exception('ERROR: tmp_path %s was neither a directory nor a file, not sure what to do to copy it to output_path %s!' % (tmp_path, output_path))
    except shutil.Error as e:
        raise Exception('ERROR: failed to copy tmp_path %s to output_path %s: %s' % (tmp_path, output_path, e))

# clean up tmp dirs
for tmp_dir in tmpdirs:
    print("gatk-tmpdir-output-wrapper.py: removing temporary directory '%s'" % (tmp_dir))
    shutil.rmtree(tmp_dir, ignore_errors=True)
    print("gatk-tmpdir-output-wrapper.py: removed temporary directory '%s'" % (tmp_dir))
    
print('gatk-tmpdir-output-wrapper.py: finished copying output, exiting with status: %s' % (gatk_exit_code), file=sys.stderr)
exit(gatk_exit_code)
