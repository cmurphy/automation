#!/usr/bin/env bash

set -x

staging_project=$1

osc='osc -A https://api.suse.de'
for p in $($osc ls $staging_project) ; do
    reqid=$($osc submitreq -m "autocheckin from jenkins" $staging_project $p home:comurphy:Fake:Cloud:8)
    reqid=${reqid#'created request id '}
    $osc request accept -m "autoaccepted" $reqid
    $osc rdelete -m "autodeleted by jenkins" $staging_project $p
done
