FROM ubuntu:14.04
MAINTAINER jcrandall@alum.mit.edu

# Install build dependencies, build fastquick from source
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install ca-certificates build-essential git cmake zlib1g-dev zlib1g && \
  cd /tmp && \
  git clone https://github.com/Griffan/FASTQuick.git && \
  cd FASTQuick && \
  git checkout 8ad9ab78 && \
  mkdir build && \
  cd build && \
  cmake .. && \
  make && \
  cp ../bin/FASTQuick /usr/local/bin/FASTQuick && \
  rm -rf /tmp/FASTQuick && \
  apt-get -q=2 -y purge ca-certificates build-essential git cmake zlib1g-dev && \
  apt-get -q=2 -y autoremove && \
  apt-get -q=2 -y clean && \
  rm -rf /var/lib/apt/lists/*

