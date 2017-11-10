#!/bin/bash
# can be run form the Git repo root dir or from the repo_dir/bin directory
# author Emmanuel Bernard

# Little dance to guess if we are in the root of the repo or not
PWD="`pwd`"
DIRNAME="`dirname $PWD`"
if [[ "$DIRNAME/bin" == "$PWD" ]];
then
    ROOT_DIR="`pwd | xargs dirname`"
else
    ROOT_DIR="`pwd`"
fi
echo $ROOT_DIR

docker run -t -i -p 4242:4242 -v $ROOT_DIR:/home/dev/infinispan.github.io:z  infinispan/infinispan.github.io
