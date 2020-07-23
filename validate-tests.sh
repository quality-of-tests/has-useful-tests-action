#!/bin/bash

set -ex

ret=0

cleanup() {
    set +e
    git checkout .
    git checkout $end
    rm -f diff.$$ fdiff.$$
}

end=$(git rev-list --simplify-by-decoration -2 HEAD|head -1)
start=$(git rev-list --simplify-by-decoration -2 HEAD|tail -1)

trap cleanup 0

git diff $start..HEAD > diff.$$
git diff $start..HEAD -- **/*test* > fdiff.$$

# No test
if [ ! -s fdiff.$$ ]; then
    echo "No test"
    if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -v '/doc/|.*\.pot?$|.*\.(rst|txt|md)$')" ]; then
	echo "Only doc"
        exit 0
    else
	echo "Code without test -> not good."
        exit 1
    fi
fi

# Only tests so no need to work further 
if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -v 'test')" ]; then
    echo "Only tests, nothing to check"
    exit 0
fi

git checkout $start

patch -p0 < fdiff.$$

if ! "$@"; then
    ret=0
else
    ret=1
fi

exit $ret

# validate-tests.sh ends here
