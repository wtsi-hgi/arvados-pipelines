import unittest
import subprocess
import tempfile
import shutil
import os

class TestWorkflowSteps(unittest.TestCase):
    def test_intersect(self):
        tmp_folder = tempfile.mkdtemp()

        self.assertEquals(subprocess.call(
            f"cwl-runner --outdir {tmp_folder} ../intersect/intersect_intervals.cwl test_intersect.yml",
            shell=True), 0)

        with open(tmp_folder + "/output.bed") as file:
            self.assertEquals(len(file.readlines()), 5)
        
        shutil.rmtree(tmp_folder)
    
    def test_workflow(self):
        tmp_folder = tempfile.mkdtemp()

        self.assertEquals(subprocess.call(
            f"cwl-runner --outdir {tmp_folder} ../workflow.cwl workflow_test.yml",
            shell=True), 0)

        self.assertEquals(len(os.listdir(tmp_folder)), 20)

if __name__ == "__main__":
    unittest.main()