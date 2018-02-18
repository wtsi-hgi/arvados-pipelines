FROM openjdk:jre-alpine3.7
LABEL author="th10@sanger.ac.uk"

RUN cd /tmp && \
    mkdir gatk && \
    cd gatk && \
    wget https://github.com/broadinstitute/gatk/releases/download/4.0.0.0/gatk-4.0.0.0.zip && \
    echo "bcbda01d226d44459daaf7dc1ed2109ae4bfd9f8  gatk-4.0.0.0.zip" | sha1sum -c - && \
    unzip gatk-4.0.0.0.zip && \
    mkdir /gatk && \
    mv gatk-4.0.0.0/gatk-package-4.0.0.0-local.jar /gatk/gatk.jar && \
    rm -rf /tmp/gatk

