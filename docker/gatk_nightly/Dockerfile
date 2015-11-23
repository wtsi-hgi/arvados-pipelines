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
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Arvados and its prerequisites
RUN \
  echo "deb http://apt.arvados.org/ trusty main" > /etc/apt/sources.list.d/apt.arvados.org.list && \
  apt-key adv --keyserver pool.sks-keyservers.net --recv 1078ECD7 && \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \
    git \
    python-pip \
    python-virtualenv \
    python-arvados-python-client \
    python-dev \
    libcurl4-gnutls-dev && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys D39DC0E3 
RUN \
  addgroup --system --gid 1593 arvados && \
  adduser --system --disabled-password --gecos 'Crunch execution user' --uid 15324 --gid 1593 crunch && \
  echo "crunch ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/crunch && \
  chmod 0440 /etc/sudoers.d/crunch && \
  install --directory --owner=crunch --group=arvados --mode=0700 /keep /tmp/crunch-src /tmp/crunch-job 

# GATK requires Sun/Oracle JDK (OpenJDK is not supported), install from PPA
RUN \
  echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install oracle-java7-installer && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk7-installer

# Set JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

# Install GRL CA
ADD grl-ca.pem /etc/ssl/certs/grl-ca.pem
RUN \
  ln -s /etc/ssl/certs/grl-ca.pem /usr/lib/ssl/certs/91155464.0 && \
  cat /etc/ssl/certs/grl-ca.pem >> /etc/ssl/certs/ca-certificates.crt && \
  cat /etc/ssl/certs/grl-ca.pem >> /usr/local/lib/python2.7/dist-packages/httplib2/cacerts.txt

# Install GATK from git repo
ADD GenomeAnalysisTK.jar /gatk/GenomeAnalysisTK.jar
WORKDIR /gatk

# Switch to crunch user and change to crunch-job work dir
USER crunch
WORKDIR /tmp/crunch-job
