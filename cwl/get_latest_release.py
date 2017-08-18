import urllib2
import json
import zipfile
from tempfile import TemporaryFile
import shutil
import io

def main():
    resp = urllib2.urlopen('https://api.github.com/repos/wtsi-hgi/gatk-cwl-generator/releases/latest')
    content = json.loads(resp.read())
    print(content["assets"][0]["browser_download_url"])
    
if __name__ == "__main__":
    main()