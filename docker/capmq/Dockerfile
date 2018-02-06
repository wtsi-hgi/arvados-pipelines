FROM ubuntu:14.04
MAINTAINER th10@sanger.ac.uk

# Install dependancies required to build htslib and capmq
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 install ca-certificates && \
  apt-get -q=2 -y --no-install-recommends install build-essential git zlib1g-dev libbz2-dev liblzma-dev libcurl4-openssl-dev libncurses5-dev automake autoconf

# Build a htslib 1.6 from source
RUN \
  cd /tmp && \
  git clone https://github.com/samtools/htslib.git && \
  cd htslib && \
  git checkout 1.6 && \
  autoreconf && \
  ./configure && \
  make && \
  make install

# Build htslib from source and copy it to /usr/local/bin
RUN \
  cd /tmp && \
  git clone https://github.com/mcshane/capmq && \
  cd capmq && \
  git checkout 0.5 && \
  make && \
  cp ./capmq /usr/local/bin/capmq

# Get rid of unused packages
RUN \
  rm -rf /tmp/htslib && \
  rm -rf /tmp/capmq && \
  apt-get -q=2 -y purge build-essential git && \
  apt-get -q=2 -y autoremove && \
  apt-get -q=2 -y clean && \
  rm -rf /var/lib/apt/lists/*

WORKDIR ~