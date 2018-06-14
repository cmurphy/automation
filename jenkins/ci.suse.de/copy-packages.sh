#!/usr/bin/env bash

set -x

osc='osc -A https://api.suse.de'

echo $project
echo $package
#requests="$(osc request list home:comurphy:Fake:Cloud:8 | awk '/State:new/{print $1}')"
#osc -A https://api.suse.de copypac --expand $project $package home:comurphy:Fake:Cloud:8:A
#osc -A https://api.suse.de comment create -c "validating" request $req
