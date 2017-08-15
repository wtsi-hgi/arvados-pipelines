import urllib2
import json
import zipfile
from tempfile import TemporaryFile

def main():
    resp = urllib2.urlopen('https://api.github.com/repos/wtsi-hgi/gatk-cwl-generator/releases/latest/')
    content = json.loads(resp.read())
    with TemporaryFile() as fp:
        fp.write(urllib2.urlopen(content["assets"][0]["browser_download_url"]).read())

if __name__ == "__main__":
    main()