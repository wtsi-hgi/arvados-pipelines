FROM ubuntu:14.04
MAINTAINER jcrandall@alum.mit.edu

# Switch to root user for installation
USER root

# Set noninteractive mode for apt conf
ENV DEBIAN_FRONTEND noninteractive

# Install updated system packages and basic prerequisites
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y upgrade && \
  apt-get -q=2 -y --no-install-recommends install \
    software-properties-common \
    python-software-properties && \
  apt-get -q=2 -y autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Arvados and its prerequisites
RUN \
  echo "deb http://apt.arvados.org/ trusty main" > /etc/apt/sources.list.d/apt.arvados.org.list && \
  apt-key adv --keyserver pool.sks-keyservers.net --recv 1078ECD7 && \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \
    git \
    python-levenshtein \
    python-pip \
    python-virtualenv \
    python-arvados-python-client \
    python-dev \
    libcurl4-gnutls-dev && \
  apt-get -q=2 -y autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys D39DC0E3 
RUN \
  addgroup --system --gid 1593 arvados && \
  adduser --system --disabled-password --gecos 'Crunch execution user' --uid 15324 --gid 1593 crunch && \
  echo "crunch ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/crunch && \
  chmod 0440 /etc/sudoers.d/crunch && \
  install --directory --owner=crunch --group=arvados --mode=0700 /keep /tmp/crunch-src /tmp/crunch-job 

# Install GRL CA
ADD grl-ca.pem /etc/ssl/certs/grl-ca.pem
RUN \
  ln -s /etc/ssl/certs/grl-ca.pem /usr/lib/ssl/certs/91155464.0 && \
  cat /etc/ssl/certs/grl-ca.pem >> /etc/ssl/certs/ca-certificates.crt

# Install telseq prerequisites
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \
    build-essential \
    cmake \
    make \
  && \
  cd /usr/local && \
  git clone git://github.com/pezmaster31/bamtools.git && \
  cd bamtools && \
  git checkout v2.4.1 && \
  mkdir build && \
  cd build && \
  cmake .. && \
  make install && \
  apt-get -q=2 -y remove \
    build-essential \
    cmake \
    make \
  && \
  apt-get -q=2 -y autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*
  
# Install telseq
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \ 
    autoconf \
    automake \
    build-essential \
    make \
 && \
  cd /usr/local && \
  git clone https://github.com/zd1/telseq.git && \
  cd telseq && \
  git checkout be185ec269dacf8934f23865c8445ab6169e11d0 && \
  cd src && \
  ./autogen.sh && \
  ./configure -with-bamtools=/usr/local && \
  make install && \
  apt-get -q=2 -y remove \
    autoconf \
    automake \
    build-essential \
    make \
  && \
  apt-get -q=2 -y autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Switch to crunch user and change to crunch-job work dir
USER crunch
WORKDIR /tmp/crunch-job
