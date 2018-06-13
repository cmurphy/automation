#!/usr/bin/env bash

set -x

osc='osc -A https://api.suse.de'
for p in $($osc ls home:comurphy:Fake:Cloud:8:A) ; do
    reqid=$($osc submitreq -m "autocheckin from jenkins" home:comurphy:Fake:Cloud:8:A $p home:comurphy:Fake:Cloud:8)
    reqid=${reqid#'created request id '}
    $osc request accept -m "autoaccepted" $reqid
    $osc rdelete home:comurphy:Fake:Cloud:8:A $p
done
