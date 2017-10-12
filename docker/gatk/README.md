A gatk image for use in this arvados pipeline.

# Building

This docker container has a dependency on JDK, however Oracle have discontinued public downloading of JDK 7. Therefore, to install the docker image, you need to first install jdk-7u25-linux-x64.tar.gz from http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase7-521261.html using an Oracle username/password and put it in this directory.

Once you have done this, you can build the docker container using to following command, substituting `<VERSION>` for the version of gatk you want.
```bash
docker build gatk -t gatk:<VERSION> --build-arg version=<VERSION>
```

Alternatively, to build all gatk versions, run `build.sh`