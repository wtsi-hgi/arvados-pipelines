from __future__ import print_function

import logging
import os
import re
import shutil
import subprocess
import tempfile
import unittest
import sys
import contextlib
import io

import cwltool.main
import schema_salad.ref_resolver

GATK_CWL_GENERATOR_VERSION = "v1.4.1"

base_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
os.environ["XDG_DATA_HOME"] = "%s/tests" % base_dir


class TestWorkflowSteps(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Get test data.
        if not os.path.isfile(f"{base_dir}/tests/cwl-example-data/chr22_cwl_test_1.cram"):
            from six.moves.urllib.request import urlopen
            import tarfile
            print("Downloading and extracting cwl-example-data")
            tgz = urlopen("https://cwl-example-data.cog.sanger.ac.uk/chr22_cwl_test.tgz")

            tar = tarfile.open(fileobj=tgz, mode="r|gz")
            tar.extractall(path=f"{base_dir}/tests/cwl-example-data")
            tar.close()
            tgz.close()

    def setUp(self):
        self._temp_folder = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self._temp_folder)

    def assert_CWLTool_call(self, cwltool_cmdline_args, **kwargs):
        def custom_schema_callback():
            with open(os.path.dirname(__file__) + "/" + "arv-cwl-schema.yaml") as arvados_schema_file:
                # TODO see why we need to load in the file twice
                # this is most likly a bug in cwltool
                # NOTE: in arvados and cwltool, they use an url which doesn't actually
                # exist in the first argument and patch the logic the Fetcher (in arvados) or
                # add an item in the cache in cwltool. To avoid a lot of extra code,
                # I've just done this this way
                cwltool.main.use_custom_schema("v1.0", f"file:///{base_dir}/cwl/tests/arv-cwl-schema.yaml", arvados_schema_file.read())

        class CWLToolWarningCapturer(logging.Handler):
            def __init__(self):
                super().__init__(logging.WARNING)
                self.invalid_warnings = []

            def should_ignore_warning(self, warning_msg):
                return re.search(r"Source 'variant-index' of type .* is partially incompatible", warning_msg) is not None

            def emit(self, record):
                if not self.should_ignore_warning(record.msg):
                    self.invalid_warnings.append(record)

        logger = logging.getLogger("cwltool")
        log_capturer = CWLToolWarningCapturer()
        logger.addHandler(log_capturer)
        with tempfile.NamedTemporaryFile("w+") as tf:
            print(f"Creating a tmp file {tf.name}")
            process = subprocess.Popen(f"tail -f {tf.name}", shell=True)
            try:
                with contextlib.redirect_stderr(tf):
                    try:
                        rval = cwltool.main.main(
                            cwltool_cmdline_args,
                            custom_schema_callback=custom_schema_callback
                        )
                    except Exception:
                        pass
            finally:
                process.kill()

            tf.seek(0)
            stderr_lines = tf.readlines()

        for stderr_line in stderr_lines:
            # a GATK error
            self.assertNotIn(" WARN ", stderr_line)
        self.assertEqual(log_capturer.invalid_warnings, [])
        self.assertEqual(rval, 0)

    def test_is_workflow_valid(self):
        self.assert_CWLTool_call([
            "--validate",
            f"{base_dir}/workflows/gatk-4.0.0.0-haplotypecaller-genotypegvcfs-libraries.cwl"
        ])

    @unittest.skip(reason="TODO: fix this test")
    def test_genotype_workflow(self):
        self.assert_CWLTool_call([
            "--outdir",
            self._temp_folder,
            f"{base_dir}/tests/genotype-gvcf-local-test.yaml"
        ])

    @unittest.skip(reason="TODO: fix this test")
    def test_cram_to_gvcfs_workflow(self):
        self.assert_CWLTool_call([
            "--outdir",
            self._temp_folder,
            f"{base_dir}/tests/library-cram-to-gvcfs-local-test.yaml"
        ])

    @unittest.skip(reason="TODO: fix this test")
    def test_overall_workflow(self):
        yml = '/tests/haploptypecaller-genotypegvcfs-local-test.yaml'
        cmd = "cwl-runner --outdir {0} {1}/{2}".format(self._temp_folder, base_dir, yml)

        rval = subprocess.call(cmd, shell=True)
        self.assertEqual(rval, 0)

        self.assertGreater(len(os.listdir(self._temp_folder)), 0)

        out_file = "%s/out.vcf" % self._temp_folder
        self.assertTrue(os.path.isfile(out_file))

        self.assertGreater(os.path.getsize(out_file), 500000)

if __name__ == '__main__':
    unittest.main()
