from __future__ import print_function
import unittest
import subprocess
import tempfile
import shutil
import os

GATK_CWL_GENERATOR_VERSION = "v1.4.1"

base_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
os.chdir(base_dir) # Make the current directory cwl
os.environ["XDG_DATA_HOME"] = "%s/tests" % base_dir


class TestWorkflowSteps(unittest.TestCase):

    @classmethod
    def setUpClass(cls):

        # Get test data.
        if not os.path.isfile("tests/cwl-example-data/chr22_cwl_test_1.cram"):
            from six.moves.urllib.request import urlopen
            import tarfile
            print("Downloading and extracting cwl-example-data")
            tgz = urlopen("https://cwl-example-data.cog.sanger.ac.uk/chr22_cwl_test.tgz")
            
            tar = tarfile.open(fileobj=tgz, mode="r|gz")
            tar.extractall(path="./tests/cwl-example-data")
            tar.close()
            tgz.close()

    def setUp(self):
        self._temp_folder = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self._temp_folder)

    def test_workflow(self):
        cwl = '/workflows/gatk-4.0.0.0-haplotypecaller-genotypegvcfs-libraries.cwl'
        
        yml = '/tests/haploptypecaller-genotypegvcfs-local-test.yaml'
        
        cmd = "cwl-runner {0}/{1} {0}/{2}".format(base_dir, cwl, yml)

        #cmd = 'ls -l'
        rval = subprocess.call(cmd,  shell=True)       
        self.assertEqual(rval, 0)

        self.assertGreater(len(os.listdir(self._temp_folder)), 0)

        out_file = "%s/out.vcf" % self._temp_folder
        self.assertTrue(os.path.isfile(out_file))

        self.assertGreater(os.path.getsize(out_file), 500000)

if __name__ == '__main__':
    unittest.main()
