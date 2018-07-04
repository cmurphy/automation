#!/usr/bin/env bash

set -x

stagingproject=$1

osc='osc -A https://api.suse.de'
for p in $($osc ls $stagingproject) ; do
    reqid=$($osc submitreq -m "autocheckin from jenkins" $stagingproject $p home:comurphy:Fake:Cloud:8)
    reqid=${reqid#'created request id '}
    $osc request accept -m "autoaccepted" $reqid
    $osc rdelete -m "autodeleted by jenkins" $stagingproject $p
done
