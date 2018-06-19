#!/usr/bin/env bash

set -x

osc() {
    /usr/bin/osc -A https://api.suse.de $@
}

if [ -d home\:comurphy\:Fake\:Cloud\:8/ardana-osconfig ] ; then
    rm -r home\:comurphy\:Fake\:Cloud\:8\:A/ardana-osconfig
fi

testproject=home:comurphy:Fake:Cloud:8:$(uuidgen)
code=$(cat <<EOF
import imp
createproject = imp.load_source('createproject', 'hostscripts/rpm-packaging/createproject.py')
createproject.create_new_build_project('out', '$testproject', 'home:comurphy:Fake:Cloud:8')
EOF
)
python -c "$code"

osc copypac --keep-link home:comurphy:Fake:Cloud:8 ardana-osconfig $testproject
osc checkout $testproject ardana-osconfig
cd $testproject/ardana-osconfig
osc rm ardana-osconfig*.obscpio
osc service disabledrun
osc add ardana-osconfig*.obscpio
osc commit -m "autocheckin test"
sleep 8
while osc results | grep '\(building\|scheduled\)' ; do
    echo "Waiting for build results"
    sleep 10
done
if ! osc results | grep succeeded ; then
    echo "Build failed"
    exit 1
fi
exit 0
