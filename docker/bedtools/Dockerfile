FROM ubuntu:14:04
LABEL author="Alejandro Barrera <alejandro.barrera@duke.edu>, Thomas Hickman <th10@sanger.ac.uk>"
# NOTE: this was originally obtained from
# https://github.com/Duke-GCB/GGR-cwl/blob/cd3a09cdaa8342f91b0ebec68cbf8f5005cef592/map/bedtools-intersect.cwl
# The MIT License (MIT)

# Copyright (c) 2016 Duke Center for Genomic and Computational Biology

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Install dependencies

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    zlib1g-dev \
    python

# Installs bedtools from compiled distribution into /opt/bedtools
ENV BEDTOOLS_RELEASE=2.25.0
ENV BEDTOOLS_URL=https://github.com/arq5x/bedtools2/releases/download/v${BEDTOOLS_RELEASE}/bedtools-${BEDTOOLS_RELEASE}.tar.gz
ENV DEST_DIR=/opt/

# Download Bedtools, decompress, compile and remove unnecessary files
RUN curl -SLo ${DEST_DIR}/bedtools-${BEDTOOLS_RELEASE}.tar.gz ${BEDTOOLS_URL} && \
    tar -xf ${DEST_DIR}/bedtools-${BEDTOOLS_RELEASE}.tar.gz -C ${DEST_DIR} && \ 
    rm ${DEST_DIR}/bedtools-${BEDTOOLS_RELEASE}.tar.gz && \
    cd ${DEST_DIR}/bedtools2 && \
    make && \
    mkdir ${DEST_DIR}/bedtools-${BEDTOOLS_RELEASE} && \
    mv bin/* ${DEST_DIR}/bedtools-${BEDTOOLS_RELEASE}/ && \
    rm -rf ${DEST_DIR}/bedtools2

# Add bedtools path to the enviroment
ENV PATH=${DEST_DIR}/bedtools-${BEDTOOLS_RELEASE}:$PATH

CMD ["bedtools"]