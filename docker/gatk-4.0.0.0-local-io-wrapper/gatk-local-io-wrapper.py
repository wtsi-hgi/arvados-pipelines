import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

# Wraps GATK to override some input and output arguments
# such that they are staged into and out of local temporary
# directories (in TMPDIR) rather than directly in the CWL
# output directory. The purpose of this is to get around
# issues with CWL engines whose native I/O support does
# not work well.
# Main use cases:
#   - as a replacement for InitialWorkDirRequirment when
#     the implementation has broken or nonexistant support
#     for `writable: true`
#   - when write patterns are random and this is not
#     supported well by the default output directory
#     (such as Arvados keep) and when native local output
#     directory support is broken (such as by consuming
#     vast amounts of memory while copying the files
#     see e.g.: https://dev.arvados.org/issues/13100).
#
# This wrapper takes extra positional arguments in
# addition to GATK's own arguments:
#   1: input argument names (a JSON array, can be empty)
#      GATK input arguments whose value represent a File
#      or Directory path that should be copied from the
#      given location to a local temporary directory
#      before being presented to GATK, such as a File in
#      an InitialWorkDir that needs to be written by GATK.
#   2: output argument names (a JSON array, can be empty)
#      GATK output arguments whose value represent a File
#      or Directory path that should be replaced with a
#      temporary directory and then copied from that
#      location to the originally specified path after
#      GATK completes. An argument can be specified in
#      both input argument names and output argument
#      names in order to support copying an input from
#      a read-only InitialWorkDir to a temporary directory,
#      having GATK operate on it there, and then copying the
#      output to the output directory after GATK completes.
#   3: extra java arguments (a JSON array, can be empty)
#      Extra arg strings to be passed to the `java` command.
#   4: The GATK command to run
#

input_argument_names_json = sys.argv[1]
output_argument_names_json = sys.argv[2]
extra_java_args_json = sys.argv[3]
gatk_command = sys.argv[4]
new_arguments = sys.argv[5:]

input2tmp = dict()
arg2input = dict()
tmp2output = dict()
tmpdirs = list()

input_argument_names = json.loads(input_argument_names_json)
if not isinstance(input_argument_names, list):
    raise Exception("ERROR: first argument to gatk-local-io-wrapper.py should be a JSON string representing a list of input arguments. Have: '%s'" % (input_argument_names_json))

output_argument_names = json.loads(output_argument_names_json)
if not isinstance(output_argument_names, list):
    raise Exception("ERROR: first argument to gatk-local-io-wrapper.py should be a JSON string representing a list of output arguments. Have: '%s'" % (output_argument_names_json))

extra_java_args = json.loads(extra_java_args_json)
if not isinstance(output_argument_names, list):
    raise Exception("ERROR: second argument to gatk-local-io-wrapper.py should be a JSON string representing a list of extra java args. Have: '%s'" % (extra_java_json))

for input_argument_name in input_argument_names:
    try:
        argument_index = new_arguments.index(input_argument_name) + 1
    except ValueError as ve:
        raise ValueError("ERROR: specified input argument '%s' was not included in the GATK arguments list: [%s]" % (input_argument_name, ','.join(new_arguments)))
    input_arg = new_arguments[argument_index]
    tmp_dir = tempfile.mkdtemp()
    print("gatk-local-io-wrapper.py: created temporary directory '%s' for input from GATK argument '%s'" % (tmp_dir, input_argument_name), file=sys.stderr)
    tmpdirs.append(tmp_dir)
    m = re.search(r'^(?P<scheme>\w+://)?(?P<path>.*)$', input_arg)
    if m:
        input_scheme = m.group('scheme') or ""
        input_path = m.group('path')
    else:
        input_scheme = ""
        input_path = input_arg
    if os.path.isabs(input_path):
        tmp_path = os.path.join(tmp_dir, input_path[1:])
    else:
        tmp_path = os.path.join(tmp_dir, input_path)
    tmp_arg = input_scheme + tmp_path
    new_arguments[argument_index] = tmp_arg
    arg2input[input_argument_name] = input_path
    input2tmp[input_path] = tmp_path
    print("gatk-local-io-wrapper.py: copying input from '%s' to '%s'" % (input_path, tmp_path), file=sys.stderr)
    try:
        if os.path.isdir(input_path):
            shutil.copytree(input_path, tmp_path)
            print("gatk-local-io-wrapper.py: successfully copied tree from '%s' to '%s'" % (input_path, tmp_path), file=sys.stderr)
        elif os.path.isfile(input_path):
            shutil.copy(input_path, tmp_path)
            print("gatk-local-io-wrapper.py: successfully copied file from '%s' to '%s'" % (input_path, tmp_path), file=sys.stderr)
        else:
            raise Exception('ERROR: input_path %s was neither a directory nor a file, not sure what to do to copy it to tmp_path %s!' % (input_path, tmp_path))
    except shutil.Error as e:
        raise Exception('ERROR: failed to copy tmp_path %s to output_path %s: %s' % (tmp_path, output_path, e))
    print("gatk-local-io-wrapper.py: redirected input for GATK argument '%s' from '%s' to '%s'" % (input_argument_name, input_arg, tmp_arg), file=sys.stderr)
    
for output_argument_name in output_argument_names:
    if output_argument_name in arg2input:
        # this argument has already been copied as an input, just register it as an output as well
        input_path = arg2input[output_argument_name]
        tmp_path = input2tmp[input_path]
        output_path = input_path # the input_path is also the output_path
        tmp2output[tmp_path] = output_path
        print("gatk-local-io-wrapper.py: output argument '%s' is also an input, will copy from tmp_path '%s' to output_path '%s' after GATK completes" % (output_argument_name, tmp_path, output_path), file=sys.stderr)
        continue
    try:
        argument_index = new_arguments.index(output_argument_name) + 1
    except ValueError as ve:
        raise ValueError("ERROR: specified output argument '%s' was not included in the GATK arguments list: [%s]" % (output_argument_name, ','.join(new_arguments)))
    output_arg = new_arguments[argument_index]
    tmp_dir = tempfile.mkdtemp()
    print("gatk-local-io-wrapper.py: created temporary directory '%s' for output from GATK argument '%s'" % (tmp_dir, output_argument_name), file=sys.stderr)
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
    print("gatk-local-io-wrapper.py: redirected output for GATK argument '%s' from '%s' to '%s'" % (output_argument_name, output_arg, tmp_arg), file=sys.stderr)
    tmp2output[tmp_path] = output_path
    print("gatk-local-io-wrapper.py: will copy from tmp_path '%s' to output_path '%s' after GATK completes" % (output_argument_name, tmp_path, output_path), file=sys.stderr)
    
gatk_command_args = ["java", "-d64"] + extra_java_args + ["-jar", "/gatk/gatk.jar", gatk_command] + new_arguments

# set hostname in /etc/hosts to squash java.net.UnknownHostException during log4j default configuration
print('gatk-local-io-wrapper.py: setting hostname in /etc/hosts', file=sys.stderr)
if subprocess.run(["bash","-c","echo 127.0.0.1 ${HOSTNAME} >> /etc/hosts"]) != 0:
    print('gatk-local-io-wrapper.py: failed to set hostname', file=sys.stderr)

# run GATK!
print('gatk-local-io-wrapper.py: running GATK: `%s`' % (' '.join([('"%s"' % arg) for arg in gatk_command_args])), file=sys.stderr)
gatk_exit_code = subprocess.run(gatk_command_args).returncode
print('gatk-local-io-wrapper.py: GATK exited with status %s' % (gatk_exit_code), file=sys.stderr)

# copy tmpdir outputs to output dirs
for tmp_path in tmp2output.keys():
    output_path = tmp2output[tmp_path]
    print("gatk-local-io-wrapper.py: copying output from tmp_path '%s' to output_path '%s'" % (tmp_path, output_path), file=sys.stderr)
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
    print("gatk-local-io-wrapper.py: removing temporary directory '%s'" % (tmp_dir), file=sys.stderr)
    shutil.rmtree(tmp_dir, ignore_errors=True)
    print("gatk-local-io-wrapper.py: removed temporary directory '%s'" % (tmp_dir), file=sys.stderr)
    
print('gatk-local-io-wrapper.py: finished copying output, exiting with status: %s' % (gatk_exit_code), file=sys.stderr)
exit(gatk_exit_code)
