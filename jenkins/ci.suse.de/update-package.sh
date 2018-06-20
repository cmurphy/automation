#!/usr/bin/env bash

set -eux

osc() {
    /usr/bin/osc -A https://api.suse.de $@
}

#FIXME: use a real programming language
declare -A pkgmap
pkgmap=( ["ardana-ansible"]="ardana-ansible" ["osconfig-ansible"]="ardana-osconfig" )
pkgname="${pkgmap[$github_repo]}"

testproject=home:comurphy:Fake:Cloud:8:$(uuidgen)
develproject=home:comurphy:Fake:Cloud:8

function cleanup() {
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
    if [ -d ./out ] ; then
        rm -r ./out
    fi
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
    pushd $testproject/$pkgname
    osc rm $pkgname*.obscpio
    osc service disabledrun
    osc add $pkgname*.obscpio
    osc commit -m "autocheckin test"
    osc results --watch
    if ! osc results | grep succeeded ; then
        echo "Build failed"
        exit 1
    fi
    popd
}

create_project
create_test_package

cleanup
exit 0
