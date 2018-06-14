#!/usr/bin/env bash

set -x

osc='osc -A https://api.suse.de'

$osc comment create -c "$test_results" request $request_id
