#/bin/sh

pushd $(dirname $0) > /dev/null
cd ..
_DIR=`pwd`
popd > /dev/null

echo ${_DIR}
pushd ${_DIR}
pub run test:test -p vm -r expanded
# popd
