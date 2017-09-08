import unittest
import subprocess
import tempfile
import shutil
import os

base_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
os.chdir(base_dir) # Make the current directory cwl

class TestWorkflowSteps(unittest.TestCase):
    def test_intersect(self):
        tmp_folder = tempfile.mkdtemp()

        self.assertEquals(subprocess.call(
            "cwl-runner --outdir {} workflow/intersect_intervals/intersect_intervals.cwl tests/test_intersect.yml".format(tmp_folder),
            shell=True), 0)

        with open(tmp_folder + "/output.bed") as file:
            self.assertEquals(len(file.readlines()), 5)
        
        shutil.rmtree(tmp_folder)
    
    def test_workflow(self):
        tmp_folder = tempfile.mkdtemp()

        self.assertEquals(subprocess.call(
            "cwl-runner --outdir {} overall_workflow.cwl tests/test_overall_workflow.yml".format(tmp_folder),
            shell=True), 0)

        self.assertEquals(len(os.listdir(tmp_folder)), 20)

if __name__ == "__main__":
    unittest.main()