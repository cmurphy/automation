#!/usr/bin/env bash

set -x

$osc='osc -A https://api.suse.de'

if [ -d home\:comurphy\:Fake\:Cloud\:8/ardana-osconfig ] ; then
    rm -r home\:comurphy\:Fake\:Cloud\:8\:A/ardana-osconfig
fi
$osc branch home:comurphy:Fake:Cloud:8 ardana-osconfig home:comurphy:Fake:Cloud:8:A
$osc checkout home:comurphy:Fake:Cloud:8:A ardana-osconfig
cd home\:comurphy\:Fake\:Cloud\:8\:A/ardana-osconfig
$osc rm ardana-osconfig*.obscpio
$osc service disabledrun
$osc add ardana-osconfig*.obscpio
$osc commit -m "autocheckin test"
sleep 2
while $osc results | grep '\(building\|scheduled\)' ; do
    echo "Waiting for build results"
    sleep 10
done
if ! $osc results | grep succeeded ; then
    echo "Build failed"
    exit 1
fi
exit 0
