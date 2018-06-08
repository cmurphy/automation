#!/usr/bin/env bash

osc='osc -A https://api.suse.de'
$osc checkout home:comurphy:Fake:Cloud:8 ardana-osconfig
cd home\:comurphy\:Fake\:Cloud\:8/ardana-osconfig
$osc rm ardana-osconfig*.obscpio
$osc service disabledrun
$osc add ardana-osconfig*.obscpio
$osc commit -m "autocheckin test"
