#/bin/bash

pushd $(dirname $(dirname $BASH_SOURCE))

# prevent test from running in parallel -j 1
pub run test -j 1 -p vm -r expanded $*

