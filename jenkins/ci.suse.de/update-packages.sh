#!/usr/bin/env bash

set -eux

osc() {
    /usr/bin/osc -A https://api.suse.de "$@"
}

SCRIPT_DIR=$(readlink -f "$(dirname $0)")
repos="ardana-ansible osconfig-ansible"

export test_project=$1

for r in $repos ; do
    export github_repo=$r
    ${SCRIPT_DIR}/update-package.sh 1>&2
done

if [ $(osc -A https://api.suse.de ls $test_project | wc -l) -gt 0 ] ; then
    for p in $(osc -A https://api.suse.de ls $test_project) ; do
        while osc results $test_project $p | grep '\(unknown\|building\|scheduled\|finished\)' >/dev/null ; do
            sleep 5
        done
        if osc results $test_project $p | grep failed >/dev/null ; then
            echo "Package $p failed to build"
            exit 1
        fi
        echo "found changes to test"
    done
fi
