FROM arvados/jobs:1.1.4.20180607205857

USER root

RUN apt-get install -y build-essential bzip2 curl xz-utils && \
    sh -c "pip install -U pip setuptools wheel" && \
    pip install py_mini_racer && \
    cd /usr/lib/python2.7/dist-packages && \
    curl https://github.com/wtsi-hgi/arvados/commit/71e0f70a3095f669e4b136c9d7624c26634db0d3.patch | git apply -p3 && \
    sed -i "1s/.*/cwltool/" /usr/lib/python2.7/dist-packages/arvados_cwl_runner-1.1.4.20180607205857-py2.7.egg-info/requires.txt && \
    pip install -e git+https://github.com/wtsi-hgi/cwltool@f2171bd7fc4865cced9c45772479dac702fdbd0c#egg=cwltool && \
    apt-get remove --purge -y build-essential bzip2 xz-utils curl && \
    apt-get -y autoremove

USER crunch
