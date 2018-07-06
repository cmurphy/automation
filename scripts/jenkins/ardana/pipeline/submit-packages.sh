#!/usr/bin/env bash

set -eux

osc() {
    /usr/bin/osc -A https://api.suse.de "$@"
}

stagingproject=$1

for p in $(osc ls $stagingproject) ; do
    reqid=$(osc submitreq -m "autocheckin from jenkins" $stagingproject $p home:comurphy:Fake:Cloud:8)
    reqid=${reqid#'created request id '}
    osc request accept -m "autoaccepted" $reqid
    osc rdelete -m "autodeleted by jenkins" $stagingproject $p
done
