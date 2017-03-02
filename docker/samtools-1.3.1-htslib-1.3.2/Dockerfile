FROM ubuntu:14.04
MAINTAINER jcrandall@alum.mit.edu

# Switch to root user for installation
USER root

# Install updated packages and prerequisites
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y upgrade && \
  apt-get -q=2 -y autoremove && \
  apt-get -q=2 -y clean && \
  rm -rf /var/lib/apt/lists/*

# Install Arvados and its prerequisites
RUN \
  echo "deb http://apt.arvados.org/ trusty main" > /etc/apt/sources.list.d/apt.arvados.org.list && \
  apt-key adv --keyserver pool.sks-keyservers.net --recv 1078ECD7 && \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \
    git \
    libcurl4-gnutls-dev \
    python-pip \
    python-virtualenv \
    python-arvados-python-client \
    python-dev \
    python-jinja2 \
    software-properties-common && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys D39DC0E3 # RERUN 201601221640
RUN \
  addgroup --system --gid 1593 arvados && \
  adduser --system --disabled-password --gecos 'Crunch execution user' --uid 15324 --gid 1593 crunch && \
  echo "crunch ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/crunch && \
  chmod 0440 /etc/sudoers.d/crunch && \
  install --directory --owner=crunch --group=arvados --mode=0700 /keep /tmp/crunch-src /tmp/crunch-job 

# Install htslib 1.3.2 + samtools 1.3.1 + bcftools 1.3.1 from source
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install build-essential git zlib1g-dev libncurses5-dev && \
  cd /tmp && \
  git clone https://github.com/samtools/htslib.git && \
  cd htslib && \
  git checkout 1.3.2 && \
  make && \
  cp htsfile /usr/local/bin && \
  cp bgzip /usr/local/bin && \
  cp tabix /usr/local/bin && \
  cd .. && \
  git clone https://github.com/samtools/samtools.git && \
  cd samtools && \
  git checkout 1.3.1 && \
  make && \
  cp samtools /usr/local/bin && \
  cd .. && \
  git clone https://github.com/samtools/bcftools.git && \
  cd bcftools && \
  git checkout 1.3.1 && \
  make && \
  cp bcftools /usr/local/bin && \
  cd && \
  rm -rf /tmp/htslib && \
  rm -rf /tmp/samtools && \
  rm -rf /tmp/bcftools && \
  apt-get -q=2 -y purge build-essential zlib1g-dev && \
  apt-get -q=2 -y autoremove && \
  apt-get -q=2 -y clean && \
  rm -rf /var/lib/apt/lists/*

# Install teepot from source
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install build-essential autoconf automake && \
  cd /tmp && \
  git clone https://github.com/wtsi-npg/teepot.git && \
  cd teepot && \
  git checkout 1.1.1 && \
  autoreconf -fvi && \
  ./configure && \
  make && \
  make install && \
  cd && \
  rm -rf /tmp/htslib && \
  rm -rf /tmp/samtools && \
  apt-get -q=2 -y purge build-essential autoconf automake && \
  apt-get -q=2 -y autoremove && \
  apt-get -q=2 -y clean && \
  rm -rf /var/lib/apt/lists/*

# Switch back to crunch user
USER crunch
