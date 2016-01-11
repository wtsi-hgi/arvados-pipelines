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
  gpg --keyserver pool.sks-keyservers.net --recv-keys D39DC0E3 
RUN \
  addgroup --system --gid 1593 arvados && \
  adduser --system --disabled-password --gecos 'Crunch execution user' --uid 15324 --gid 1593 crunch && \
  echo "crunch ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/crunch && \
  chmod 0440 /etc/sudoers.d/crunch && \
  install --directory --owner=crunch --group=arvados --mode=0700 /keep /tmp/crunch-src /tmp/crunch-job 

# Install experimental bcftools (with gVCF support) and htsfile from source
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install build-essential git zlib1g-dev && \
  cd /tmp && \
  git clone --branch=exp/gvcf --recursive git://github.com/pd3/bcftools.git && \
  cd bcftools && \
  make && \
  cp bcftools /usr/local/bin && \
  cd htslib && \
  make && \
  cp htsfile /usr/local/bin && \
  cd && \
  rm -rf /tmp/bcftools && \
  apt-get -q=2 -y purge build-essential zlib1g-dev && \
  apt-get -q=2 -y autoremove && \
  apt-get -q=2 -y clean && \
  rm -rf /var/lib/apt/lists/*

# Install vr-runner
RUN \
  apt-add-repository multiverse && \
  apt-get -q=2 update && \
  apt-get -q=2 -y --no-install-recommends install \
    git \
    libmath-random-perl \
    libipc-run3-perl \
  && \
  cd /tmp && \
  git clone https://github.com/wtsi-hgi/vr-runner.git && \
  cd vr-runner && \
  git checkout c935e17ab64b48c5efa106176b8630de3a25e8eb && \
  cp scripts/run-* /usr/local/bin && \
  mkdir -p /usr/local/lib/site_perl && \
  cp -r modules/* /usr/local/lib/site_perl/ && \
  cd && \
  rm -rf /tmp/vr-runner && \
  apt-get -q=2 -y autoremove && \
  apt-get -q=2 -y clean && \
  rm -rf /var/lib/apt/lists/*

# Install GRL CA
ADD grl-ca.pem /etc/ssl/certs/grl-ca.pem
RUN \
  ln -s /etc/ssl/certs/grl-ca.pem /usr/lib/ssl/certs/91155464.0 && \
  cat /etc/ssl/certs/grl-ca.pem >> /etc/ssl/certs/ca-certificates.crt && \
  cat /etc/ssl/certs/grl-ca.pem >> /usr/local/lib/python2.7/dist-packages/httplib2/cacerts.txt

# Install runner configuration templates
ADD gvcf.mpileup.conf.j2 /etc/runner/gvcf.mpileup.conf.j2
ADD gvcf.calling.conf.j2 /etc/runner/gvcf.calling.conf.j2

# Switch back to crunch user
USER crunch
