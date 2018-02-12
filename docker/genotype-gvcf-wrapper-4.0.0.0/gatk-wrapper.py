import os
import shutil
import sys
import tempfile
import subprocess

new_arguments = sys.argv[1:]

variant_folder_index = new_arguments.index("--variant") + 1
variant_folder = new_arguments[variant_folder_index]
new_location = os.path.join(tempfile.gettempdir(), os.path.basename(variant_folder))
print(f"Copying variant folder {variant_folder} to {new_location}")
shutil.copytree(variant_folder, new_location)

new_arguments[variant_folder_index] = "gendb://" + new_location

gatk_command = [
    "java",
    "-D64",
    "-Xmx4g",
    "-jar",
    "/gatk/gatk.jar",
    "GenotypeGVCFs"
]

exit(subprocess.run(gatk_command + new_arguments).returncode)
