#!/usr/bin/env bash

set -x

osc () {
    osc -A https://api.suse.de $@
}

test_results=$1

$osc comment create -c "$test_results" request $request_id
