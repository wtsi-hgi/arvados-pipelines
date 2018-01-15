FROM ubuntu:16.04
MAINTAINER jcrandall@alum.mit.edu

# Install perl and fetch misc/seq_cache_populate.pl from samtools repo
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 install ca-certificates && \
  apt-get -q=2 -y --no-install-recommends install git perl && \
  cd /tmp && \
  git clone https://github.com/samtools/samtools.git && \
  cd samtools && \
  git checkout 1.6 && \
  cp misc/seq_cache_populate.pl /usr/local/bin && \
  cd && \
  rm -rf /tmp/samtools && \
  apt-get -q=2 -y purge ca-certificates git && \
  apt-get -q=2 -y autoremove && \
  apt-get -q=2 -y clean && \
  rm -rf /var/lib/apt/lists/*

