#!/usr/bin/env python

import contextlib
import glob
import json
import os
import re
import shutil
import sys
import tempfile
import time

import requests

import sh


def project_map():
    map_file = os.path.join(os.path.dirname(__file__), 'project-map.json')
    with open(map_file) as map:
        project_map = json.load(map)
    return project_map


@contextlib.contextmanager
def cd(dir):
    pwd = os.getcwd()
    try:
        os.chdir(dir)
        yield
    finally:
        os.chdir(pwd)


class GerritChange:

    GERRIT = 'https://gerrit.suse.provo.cloud'

    def __init__(self, change_id):
        self.id = change_id
        query_url = '%(gerrit)s/changes/%(change_id)s/?o=CURRENT_REVISION' % {
            'gerrit': self.GERRIT, 'change_id': self.id}
        response = requests.get(query_url)
        self._change_object = json.loads(response.text.replace(")]}'", ''))
        self.project = self._change_object['project'].split('/')[1]
        current_revision = self._change_object['current_revision']
        fetch_obj = self._change_object['revisions'][current_revision]['fetch']
        self.url = fetch_obj['anonymous http']['url']
        self.ref = fetch_obj['anonymous http']['ref']
        self.target = self._change_object['branch']

    def prep_workspace(self):
        if os.path.exists('./source'):
            shutil.rmtree('./source')
        os.mkdir('source')
        with cd('source'):
            sh.git('clone', self.url, '%s.git' % self.project)
            with cd('%s.git' % self.project):
                sh.git('checkout', '-b', 'test-merge', self.target)
                sh.git('fetch', self.url, self.ref)
                sh.git('merge', '--no-edit', 'FETCH_HEAD')


def test_project_name(change_id, homeproject):
    return '%s:ardana-ci-%s' % (homeproject, change_id)


def create_test_project(change_id, develproject, testproject):
    repo_metadata = """
<project name="%(testproject)s">
  <title>Autogenerated CI project</title>
  <description/>
  <link project="%(develproject)s"/>
  <person userid="opensuseapibmw" role="maintainer"/>
  <publish>
    <enable repository="standard"/>
  </publish>
  <repository name="standard" rebuild="direct" block="local"
      linkedbuild="localdep">
    <path project="%(develproject)s" repository="SLE_12_SP3"/>
    <arch>x86_64</arch>
  </repository>
</project>
""" % {'testproject': testproject, 'develproject': develproject}

    with tempfile.NamedTemporaryFile() as meta:
        meta.write(repo_metadata)
        meta.flush()
        sh.osc('-A', 'https://api.suse.de', 'api', '-T', meta.name,
               '/source/%s/_meta' % testproject)

    return testproject


def wait_for_build():
    # Wait for build to be scheduled
    while 'unknown' in sh.osc('results'):
        time.sleep(3)
    results = sh.osc('results', '--watch')
    if 'succeeded' not in results:
        print("Package build failed.")
        sys.exit(1)


def create_test_package(change, develproject, testproject):
    package_name = project_map()[change.project]
    sh.osc('-A', 'https://api.suse.de', 'copypac', '--keep-link',
           develproject, package_name, testproject)
    sh.osc('-A', 'https://api.suse.de', 'checkout', testproject, package_name)
    source_dir = '%s/source/%s.git' % (os.getcwd(), change.project)
    with cd('%s/%s' % (testproject, package_name)):
        with open('_service', 'r+') as service_file:
            service_def = service_file.read()
            service_def = re.sub(r'<param name="url">.*</param>',
                                 '<param name="url">%s</param>' % source_dir,
                                 service_def)
            service_def = re.sub(r'<param name="revision">.*</param>',
                                 '<param name="revision">test-merge</param>',
                                 service_def)
            service_file.seek(0)
            service_file.write(service_def)
            service_file.truncate()
        sh.osc('rm', glob.glob('%s*.obscpio' % package_name))
        sh.osc('service', 'disabledrun')
        sh.osc('add', glob.glob('%s*.obscpio' % package_name))
        sh.osc('commit', '-m', 'Testing change %s' % change.id)
        wait_for_build()


def cleanup(testproject):
    if os.path.exists('./source'):
        shutil.rmtree('./source')
    if os.path.exists('./%s' % testproject):
        shutil.rmtree('./%s' % testproject)


def main():
    change_id = os.environ['gerrit_change_id']
    develproject = os.environ['develproject']
    homeproject = os.environ['homeproject']
    change = GerritChange(change_id)
    testproject = test_project_name(change.id, homeproject)
    cleanup(testproject)
    change.prep_workspace()
    testproject = create_test_project(change.id, develproject, testproject)
    create_test_package(change, develproject, testproject)
    cleanup(testproject)


if __name__ == '__main__':
    main()