#!/usr/bin/env bash

set -x

osc() {
    osc -A https://api.suse.de $@
}

osc rdelete -m "autodeleted by jenkins" home:comurphy:Fake:Cloud:8:A ardana-osconfig
