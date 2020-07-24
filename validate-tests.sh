#!/bin/bash

set -e

ret=0

cleanup() {
    set +e
    git checkout . >& /dev/null
    git checkout $end >& /dev/null
    rm -f diff.$$ fdiff.$$
}

if [ "$1" = '-v' ]; then
    shift
    verbose=1
    set -x
    pwd
    env
fi

mainbranch=$(LC_ALL=C git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | tr -d ' ')

if [ -n "$mainbranch" ]; then
    mainbranch="origin/$mainbranch"
else
    mainbranch=origin/master
fi

end=$(git rev-parse --abbrev-ref HEAD)
start=$(git merge-base $end $mainbranch)

trap cleanup 0

git diff $start..HEAD > diff.$$
git diff $start..HEAD -- '**/*test*' > fdiff.$$

# No test
if [ ! -s fdiff.$$ ]; then
    echo "No test"
    if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -vi 'changelog|readme|/doc/|.*\.pot?$|.*\.(rst|txt|md|sample)$|makefile|Dockerfile|docker-compose\.y|(^|/)\..+')" ]; then
	echo "Only doc/build/infra -> good."
        exit 0
    else
	echo "Code without test -> not good."
        exit 1
    fi
fi

# Only tests so no need to work further 
if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -v 'test')" ]; then
    echo "Only tests, nothing to check --> good."
    exit 0
fi

if [ "$verbose" = 1 ]; then
    git checkout $start
else
    git checkout $start >& /dev/null
fi

# Checking with the tests from the changeset without any code
patch -p1 < fdiff.$$

# Test should fail to validate that it is testing changes from the new
# code that is not present
if ! "$@"; then
    echo "Tests are failing -> good"
    ret=0
else
    echo "Tests are not failing -> bad"
    ret=1
fi

exit $ret

# validate-tests.sh ends here
