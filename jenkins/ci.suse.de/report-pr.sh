#!/usr/bin/env bash

set -eux

pr=$(echo $github_pr | cut -d ':' -f 1)
sha=$(echo $github_pr | cut -d ':' -f 2)

export OCTOKIT_NETRC_FILE=./.cmurphy-netrc
function cleanup() {
  rm -f ./.cmurphy-netrc
}
trap "cleanup" ERR
wget https://gist.githubusercontent.com/cmurphy/5160df8d37e433582ca6755c6713d4e6/raw/3ff93766e60a65ceef95892d592e3444c3ea10bc/.cmurphy-netrc
chmod 600 ./.cmurphy-netrc

~/github.com/openSUSE/github-pr/github_pr.rb -a set-status \
    --status ${test_results} \
    --org ${github_org} \
    --repo ${github_repo} \
    --pr ${pr} \
    --sha ${sha} \
    --context 'suse/ardana/testbuild'
