FROM arvados/jobs:1.1.4.20180607205857

USER root

RUN echo 201809021158

RUN apt-get update -y && \
    apt-get install -y build-essential bzip2 curl xz-utils docker && \
    sh -c "pip install -U pip setuptools wheel" && \
    pip install py_mini_racer && \
    cd /usr/lib/python2.7/dist-packages && \
    curl https://patch-diff.githubusercontent.com/raw/curoverse/arvados/pull/68.patch | patch -p3 && \
    curl https://patch-diff.githubusercontent.com/raw/curoverse/arvados/pull/67.patch | patch -p3 && \
    curl https://patch-diff.githubusercontent.com/raw/curoverse/arvados/pull/78.patch | patch -p3 && \
    curl https://patch-diff.githubusercontent.com/raw/curoverse/arvados/pull/81.patch | patch -p3 && \
    curl https://github.com/curoverse/arvados/commit/fc582bfe0561092165f45b7b6f4d0025892aebfd.patch | patch -p3 && \
    curl https://patch-diff.githubusercontent.com/raw/wtsi-hgi/arvados/pull/13.patch | sed '/From bf61e04cae19ac003af8b9734a42c622d860c281/q' | head -n -1 | patch -p3 && \
    curl https://github.com/common-workflow-language/cwltool/compare/1.0.20180524215209...wtsi-hgi:mini_racer_patch2.patch | patch -p1 && \
    sed -i "1s/.*/cwltool/" /usr/lib/python2.7/dist-packages/arvados_cwl_runner-1.1.4.20180607205857-py2.7.egg-info/requires.txt && \
    apt-get remove --purge -y build-essential bzip2 xz-utils curl && \
    apt-get -y autoremove

USER crunch
