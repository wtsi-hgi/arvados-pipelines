FROM ubuntu:14.04
MAINTAINER jcrandall@alum.mit.edu

# Install build dependencies, build fastquick from source
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 install ca-certificates && \
  apt-get -q=2 -y --no-install-recommends install build-essential git cmake zlib1g-dev

RUN \
  cd /tmp && \
  git clone https://github.com/Griffan/FASTQuick.git && \
  cd FASTQuick && \
  git checkout 8ad9ab78 && \
  mkdir build && \
  cd build && \
  cmake .. && \
  make && \
  cp ../bin/FASTQuick /usr/local/bin/FASTQuick

# Get rid of unused packages
# RUN \
#   rm -rf /tmp/htslib && \
#   rm -rf /tmp/capmq && \
#   apt-get -q=2 -y purge build-essential git && \
#   apt-get -q=2 -y autoremove && \
#   apt-get -q=2 -y clean && \
#   rm -rf /var/lib/apt/lists/*

