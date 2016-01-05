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

# Install GATK requirements
# Sun/Oracle JDK is required (OpenJDK is not supported)
COPY jdk-wgetrc /tmp/jdk-wgetrc
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \
    wget && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  cd /tmp && \
  WGETRC=/tmp/jdk-wgetrc \
  J_DIR=jdk1.7.0_25 \
  SHA256SUM=f80dff0e19ca8d038cf7fe3aaa89538496b80950f4d10ff5f457988ae159b2a6 \
  FILENAME=jdk-7u25-linux-x64.tar.gz \
  PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/7u25-b15/$FILENAME && \
  wget --continue --no-check-certificate -O ${FILENAME} --header "Cookie: oraclelicense=a" $PARTNER_URL && \
  echo "${SHA256SUM} ${FILENAME}" | sha256sum -c && \
  tar xf ${FILENAME} && \
  mkdir -p /opt && \
  mv ${J_DIR} /opt/ && \
  rm -f ${FILENAME}
ENV JAVA_HOME /opt/jdk1.7.0_25
ENV PATH /opt/jdk1.7.0_25/bin:${PATH}

# Install prerequisites for HGI Crunch Scripts
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \
    python-levenshtein && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install GRL CA
ADD grl-ca.pem /etc/ssl/certs/grl-ca.pem
RUN \
  ln -s /etc/ssl/certs/grl-ca.pem /usr/lib/ssl/certs/91155464.0 && \
  cat /etc/ssl/certs/grl-ca.pem >> /etc/ssl/certs/ca-certificates.crt && \
  cat /etc/ssl/certs/grl-ca.pem >> /usr/local/lib/python2.7/dist-packages/httplib2/cacerts.txt

# Install GATK from git source
RUN \
  cd /tmp && \
  wget http://mirror.vorboss.net/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
  echo "516923b3955b6035ba6b0a5b031fbd8b apache-maven-3.3.9-bin.tar.gz" | md5sum -c && \
  tar xf apache-maven-3.3.9-bin.tar.gz && \
  rm -f apache-maven-3.3.9-bin.tar.gz && \
  git clone https://github.com/wtsi-hgi/gatk-protected.git && \
  cd gatk-protected && \
  git checkout f93505db34b9289bf62c8b446cf9699095bdaa79 && \
  /tmp/apache-maven-3.3.9/bin/mvn verify -P\!queue && \
  mkdir -p /gatk && \
  cp target/GenomeAnalysisTK.jar /gatk/GenomeAnalysisTK.jar && \
  rm -rf /tmp/apache-maven-3.3.9 && \
  rm -rf /tmp/gatk-protected

# Switch to crunch user and change to crunch-job work dir
USER crunch
WORKDIR /tmp/crunch-job
