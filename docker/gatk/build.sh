VERSIONS="3.4
3.5
3.6
3.7
3.8"


for version in $VERSIONS
do
    docker build . -t gatk:$version --build-arg version=$version
done