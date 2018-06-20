#!/usr/bin/env bash

set -x

osc() {
    /usr/bin/osc -A https://api.suse.de $@
}

pkgname=ardana-${github_repo%-ansible}
testproject=home:comurphy:Fake:Cloud:8:$(uuidgen)
develproject=home:comurphy:Fake:Cloud:8

function cleanup() {
    if [ -z "$WORKSPACE" ] ; then
        echo "WORKSPACE not defined"
        exit 1
    fi
    if [ -d $WORKSPACE/$testproject/$pkgname ] ; then
        osc delete $WORKSPACE/$testproject/$pkgname
        rm -r $WORKSPACE/$testproject
    fi
    if [ -d $WORKSPACE/out ] ; then
        rm -r $WORKSPACE/out
    fi
}
trap cleanup ERR

function create_project() {
    code=$(cat <<EOF
import imp
createproject = imp.load_source('createproject', 'hostscripts/rpm-packaging/createproject.py')
createproject.create_new_build_project('out', '$testproject', '$develproject')
EOF
    )
    python -c "$code"
}

function create_test_package() {
    osc copypac --keep-link $develproject $pkgname $testproject
    osc checkout $testproject $pkgname
    cd $testproject/$pkgname
    osc rm $pkgname*.obscpio
    osc service disabledrun
    osc add $pkgname*.obscpio
    osc commit -m "autocheckin test"
}

function wait_for_build() {
    sleep 8
    while osc results | grep '\(building\|scheduled\|finished\)' ; do
        echo "Waiting for build results"
        sleep 10
    done
    if ! osc results | grep succeeded ; then
        echo "Build failed"
        exit 1
    fi
}

create_project
create_test_package
wait_for_build

cleanup
exit 0
