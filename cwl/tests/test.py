from __future__ import print_function
import pytest
import subprocess
import tempfile
import shutil
import os

GATK_CWL_GENERATOR_VERSION="v1.4.1"

"""
Download example data to be used in CWL integration tests
"""
@pytest.fixture(scope="module")
def example_data():
    if not os.path.isfile("tests/cwl-example-data/chr22_cwl_test.cram"):
        from six.moves.urllib.request import urlopen
        import tarfile
        print("Downloading and extracting cwl-example-data")
        tgz = urlopen("https://cwl-example-data.cog.sanger.ac.uk/chr22_cwl_test.tgz")
        tar = tarfile.open(fileobj=tgz, mode="r|gz")
        tar.extractall(path="./tests/cwl-example-data")
        tar.close()
        tgz.close()

def ensure_docker_build(image):
    p = subprocess.Popen(["docker", "build", "-t", image, "tools/%s" % (image)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdout, stderr) = p.communicate()
    rval = p.wait()
    if rval != 0:
        raise Exception("docker build returned %s: %s %s" % (rval, stderr, stdout))

"""
Ensure docker images are built locally
"""
@pytest.fixture(scope="module")
def docker_images():
    for image in ["dict_to_interval_list", "split_interval_list", "intersect_intervals"]:
        print("Building docker image %s" % image)
        ensure_docker_build(image)

base_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
os.chdir(base_dir) # Make the current directory cwl
os.environ["XDG_DATA_HOME"] = "%s/tests" % (base_dir)

class TestWorkflowSteps:
    def test_intersect(self, docker_images):
        tmp_folder = tempfile.mkdtemp()

        rval = subprocess.call(
            "cwl-runner --outdir {} tools/intersect_intervals/intersect_intervals.cwl tests/test_intersect.yml".format(tmp_folder),
            shell=True)
        assert rval == 0

        with open(tmp_folder + "/output.bed") as file:
            assert len(file.readlines()) == 5

        shutil.rmtree(tmp_folder)

    def test_workflow(self, docker_images, example_data):
        tmp_folder = tempfile.mkdtemp()

        rval = subprocess.call(
            "cwl-runner --debug --js-console --outdir {} overall_workflow.cwl tests/test_overall_workflow.yml".format(tmp_folder),
            shell=True)
        assert rval == 0

        assert len(os.listdir(tmp_folder)) > 0

        out_file = "%s/out.vcf" % (tmp_folder)
        assert os.path.isfile(out_file)

        assert os.path.getsize(out_file) > 500000

        shutil.rmtree(tmp_folder)
