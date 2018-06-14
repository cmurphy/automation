#!/usr/bin/env bash

set -x

osc='osc -A https://api.suse.de'

read -r home_project package <<< $( $osc -A https://api.suse.de request show $request_id | awk '/submit:/{split($2,x,"/"); split(x[2],y,"@"); print x[1],y[1]}' )
$osc -A https://api.suse.de copypac --expand $home_project $package home:comurphy:Fake:Cloud:8:A
sleep 8
while $osc results home:comurphy:Fake:Cloud:8:A $package | grep '\(building\|scheduled\)' ; do
    echo "Waiting for build results"
    sleep 10
done
if ! $osc results home:comurphy:Fake:Cloud:8:A $package | grep succeeded ; then
    echo "Build failed"
    exit 1
fi
exit 0
