#!/usr/bin/env bash

set -eux

osc() {
    /usr/bin/osc -A https://api.suse.de "$@"
}

function select_staging_project() {
    echo "home:comurphy:Fake:Cloud:8:A"
}

SCRIPT_DIR=$(readlink -f "$(dirname $0)")
repos="ardana-ansible osconfig-ansible"
export testproject=$(select_staging_project)
for r in $repos ; do
    export github_repo=$r
    ${SCRIPT_DIR}/update-package.sh 1>&2
done

if [ $(osc -A https://api.suse.de ls $testproject | wc -l) -gt 0 ] ; then
    for p in $(osc -A https://api.suse.de ls $testproject) ; do
        while osc results $testproject $p | grep '\(unknown\|building\|scheduled\|finished\)' >/dev/null ; do
            sleep 5
        done
        if osc results $testproject $p | grep failed >/dev/null ; then
            echo "Package $p failed to build"
            exit 1
        fi
    done
else
    testproject=''
fi

echo $testproject
