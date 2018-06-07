#!/usr/bin/env python

import json
import requests

org, repo, pr_str = sys.argv[1:]
pr_id = pr_str.split(':')[0]
pr_url = 'https://api.github.com/repos/%(org)s/$(repo)s/pulls/$(pr_id)s' %
             { 'org': org, 'repo': repo, 'pr_id': pr_id }
pr = requests.get(pr_url)
merged = json.loads(pr)['merged']
if merged:
    exit 0
else:
    exit 1
