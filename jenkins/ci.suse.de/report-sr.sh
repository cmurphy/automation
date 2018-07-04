#!/usr/bin/env bash

set -eux

osc () {
    /usr/bin/osc -A https://api.suse.de $@
}

test_results=$1

osc comment create -c "$test_results" request $submitrequest_id
