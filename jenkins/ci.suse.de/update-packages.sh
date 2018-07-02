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
    ${SCRIPT_DIR}/update-package.sh
done

if [ $(osc -A https://api.suse.de ls $testproject | wc -l) -gt 0 ] ; then
    for p in $(osc -A https://api.suse.de ls $testproject) ; do
        osc -A https://api.suse.de results --watch $testproject $p
    done
else
    testproject=''
fi

echo $testproject
