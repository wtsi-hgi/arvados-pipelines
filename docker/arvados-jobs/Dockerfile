FROM arvados/jobs:1.1.4.20180607205857

USER root

RUN apt-get install -y build-essential bzip2 curl xz-utils && \
    sh -c "pip install -U pip setuptools wheel" && \
    pip install py_mini_racer && \
    cd /usr/lib/python2.7/dist-packages && \
    curl https://github.com/wtsi-hgi/arvados/commit/71e0f70a3095f669e4b136c9d7624c26634db0d3.patch | patch -p3 && \
    curl https://github.com/common-workflow-language/cwltool/compare/1.0.20180524215209...wtsi-hgi:1.0.20180524215209-mini_racer_js.patch | patch -p1 && \
    sed -i "1s/.*/cwltool/" /usr/lib/python2.7/dist-packages/arvados_cwl_runner-1.1.4.20180607205857-py2.7.egg-info/requires.txt && \
    apt-get remove --purge -y build-essential bzip2 xz-utils curl && \
    apt-get -y autoremove

USER crunch
