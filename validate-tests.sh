#!/bin/bash

set -e

ret=0

cleanup() {
    set +e
    git checkout . >& /dev/null
    git clean -df  >& /dev/null
    git checkout $end >& /dev/null || git checkout $sha >& /dev/null
    rm -f diff.$$ fdiff.$$
}

# Syntax: validate-tests.sh <test command line>

if [ "$VERBOSE" = 'true' ]; then
    set -x
    pwd
    env
fi

if [ -n "$GITHUB_EVENT_PATH" ]; then
    if [ "$VERBOSE" = 'true' ]; then
        jq . "$GITHUB_EVENT_PATH"
    fi
    baseref=$(jq -r .pull_request.base.ref "$GITHUB_EVENT_PATH")
fi

if git log -1 | grep -qi "^\s*Change-Id:\s*.*"; then
    gerrit=1
    remote=gerrit
else
    gerrit=
    remote=origin
fi

if [ -n "$GITHUB_HEAD_REF" ]; then
    end=$GITHUB_HEAD_REF
else
    end=$(git rev-parse --abbrev-ref HEAD)
fi

sha=$(git rev-parse HEAD)

if [ -z "$gerrit" ]; then
    echo "Fetching $remote $end..."
    git fetch $remote $end

    echo "Fetching $remote $baseref..."

    if [ -n "$baseref" -a "$baseref" != 'null' ]; then
        git fetch $remote $baseref
        basebranch="$baseref"
    else
        git fetch $remote master
        basebranch=master
    fi

    start=$(git merge-base $basebranch $end || git merge-base $remote/$basebranch $remote/$end)

    trap cleanup 0

    git diff --no-prefix $start..$sha > diff.$$
    git diff --no-prefix $start..$sha -- '**/*test*' > fdiff.$$
else
    trap cleanup 0

    git show --no-prefix > diff.$$
    git diff --no-prefix HEAD^..HEAD -- '**/*test*' > fdiff.$$

    start=HEAD^
fi

# No test
if [ ! -s fdiff.$$ ]; then
    echo "No test"
    if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -vi 'changelog|readme|/doc/|.*\.pot?$|.*\.(rst|txt|md|sample)$|makefile|Dockerfile|docker-compose\.y|package.*\.json|yarn\.lock|(^|/)\..+')" ]; then
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

if [ "$VERBOSE" = 'true' ]; then
    git checkout $start
else
    git checkout $start >& /dev/null
fi

# Checking with the tests from the changeset without any code
patch -p0 < fdiff.$$

# Test should fail to validate that it is testing changes from the new
# code that is not present
echo "Running tests: $@..."
if ! "$@"; then
    echo "Tests are failing -> good"
    ret=0
else
    echo "Tests are not failing -> bad"
    ret=1
fi

exit $ret

# validate-tests.sh ends here
