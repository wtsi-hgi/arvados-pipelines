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
# Oracle have discontinued public downloading of JDK 7
# To build this docker container, you must use an Oracle username/password to 
# download jdk-7u25-linux-x64.tar.gz from Oracle and put it in the same 
# directory as this Dockerfile.
# Download from: http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase7-521261.html
COPY jdk-7u25-linux-x64.tar.gz /tmp/jdk-7u25-linux-x64.tar.gz
RUN \
  cd /tmp && \
  J_DIR=jdk1.7.0_25 \
  SHA256SUM=f80dff0e19ca8d038cf7fe3aaa89538496b80950f4d10ff5f457988ae159b2a6 \
  FILENAME=jdk-7u25-linux-x64.tar.gz && \
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

# Install GATK from git source
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \
    wget && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  cd /tmp && \
  wget http://mirror.vorboss.net/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
  echo "516923b3955b6035ba6b0a5b031fbd8b apache-maven-3.3.9-bin.tar.gz" | md5sum -c && \
  tar xf apache-maven-3.3.9-bin.tar.gz && \
  rm -f apache-maven-3.3.9-bin.tar.gz && \
  git clone https://github.com/broadgsa/gatk-protected.git && \
  cd gatk-protected && \
  git checkout 3.5 && \
  /tmp/apache-maven-3.3.9/bin/mvn verify -P\!queue && \
  mkdir -p /gatk && \
  cp target/GenomeAnalysisTK.jar /gatk/GenomeAnalysisTK.jar && \
  rm -rf /tmp/apache-maven-3.3.9 && \
  rm -rf /tmp/gatk-protected

#Install dependencies, homebrew, Node.js
RUN \
  apt-get update && \
  apt-get install -y nodejs npm
  #apt-get install build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev && \
 # ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && \
#  brew install node && \
#  apt-get install nodejs && \
 # apt-get install npm 

#Install cwl-runner, cwltools, git directories
RUN \
  pip install cwlref-runner && \
  pip install cwltool && \
  git clone https://github.com/yejinyou/PY.git

# Download GATK commandlind arguments
RUN \
  cd /PY && \
  #mkdir /jsonfiles && \
  #cd /jsonfiles && \
  wget -O CommandLineGATK https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_gatk_engine_CommandLineGATK.php.json && \
  wget -O HaplotypeCaller https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_gatk_tools_walkers_haplotypecaller_HaplotypeCaller.php.json
#  sudo python docker_json2cwl.py

 
# Switch to crunch user and change to crunch-job work dir
USER crunch
WORKDIR /tmp/crunch-job
