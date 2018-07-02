#!/usr/bin/env bash

set -eux

osc() {
    /usr/bin/osc -A https://api.suse.de "$@"
}

#FIXME: use a real programming language
declare -A pkgmap
pkgmap=( ["ardana-ansible"]="ardana-ansible" ["osconfig-ansible"]="ardana-osconfig" )
pkgname="${pkgmap[$github_repo]}"

develproject=home:comurphy:Fake:Cloud:8

function cleanup() {
    if [ -d $WORKSPACE/$testproject/$pkgname ] ; then
        osc delete $WORKSPACE/$testproject/$pkgname
        rm -r $WORKSPACE/$testproject
    fi
    if [ -d $WORKSPACE/out ] ; then
        rm -r $WORKSPACE/out
    fi
    if [ -d $WORKSPACE/source/${github_repo}.git ] ; then
        rm -rf $WORKSPACE/source/${github_repo}.git
    fi
}

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

function create_source_merge() {
    local pr_id=$(echo $github_pr | cut -d ':' -f 1)
    local target_branch=$(echo $github_pr | cut -d ':' -f 3)

    mkdir -p source
    git clone https://github.com/${github_org}/${github_repo}.git source/${github_repo}.git
    pushd source/${github_repo}.git
    git fetch origin pull/${pr_id}/head
    git checkout -b test-merge $target_branch
    git merge --no-edit FETCH_HEAD
    popd
}

function unchanged() {
    osc status | grep -e "^[ADM]" >/dev/null
}

function create_test_package() {
    osc copypac --keep-link $develproject $pkgname $testproject
    osc checkout $testproject $pkgname
    pushd $testproject/$pkgname
    if is_pr ; then
        sed -i -e 's#<param name="url">.*</param>#<param name="url">'${WORKSPACE}'/source/ardana-ansible.git</param>#' _service
        sed -i -e 's#<param name="revision">.*</param>#<param name="revision">test-merge</param>#' _service
    fi
    osc rm $pkgname*.obscpio
    osc service disabledrun
    osc add $pkgname*.obscpio
    if unchanged ; then
        osc rdelete -m "autoremoved" $testproject $pkgname
        cleanup
        exit 0
    fi
    osc commit -m "autocheckin test"
    osc status
    osc --version
    # Wait for build to be scheduled
    while osc results | grep unknown ; do
        sleep 5
    done
    osc results --watch
    if ! osc results | grep succeeded ; then
        echo "Build failed"
        exit 1
    fi
    popd
}

function is_pr() {
    test -n "${github_pr:-}"
}

function select_staging_project() {
    echo "home:comurphy:Fake:Cloud:8:A"
}

if is_pr ; then
    testproject=home:comurphy:Fake:Cloud:8:${github_pr}
    trap cleanup EXIT ERR
    create_project
    create_source_merge
else
    testproject=$(select_staging_project)
    trap cleanup EXIT ERR
fi
cleanup
create_test_package

cleanup
echo $testproject
