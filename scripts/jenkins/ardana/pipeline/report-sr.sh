#!/usr/bin/env bash

set -eux

osc () {
    /usr/bin/osc -A https://api.suse.de "$@"
}

test_results=$1

# TODO: This could change the review state or modify another attribute rather
# than adding a comment
osc comment create -c "$test_results" request $submitrequest_id
