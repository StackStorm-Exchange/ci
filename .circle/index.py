#!/usr/bin/env python
from __future__ import print_function

import argparse
import hashlib
import json
import os
import subprocess
import time
from collections import OrderedDict
from glob import glob
import yaml

import requests
import six

from st2common.util.pack import get_pack_ref_from_metadata

EXCHANGE_NAME = "StackStorm-Exchange"
EXCHANGE_PREFIX = "stackstorm"

GITHUB_USERNAME = os.environ.get('MACHINE_USER')
GITHUB_PASSWORD = os.environ.get("MACHINE_PASSWORD", os.environ.get("GH_TOKEN"))

SESSION = requests.Session()
SESSION.auth = (GITHUB_USERNAME, GITHUB_PASSWORD)

PACK_VERSIONS = {}

GQL_PACK_TAGS_QUERY = """
query ($owner: String!, $per_page: Int = 100, $endCursor: String) {
  repositoryOwner(login: $owner) {
    repositories(first: $per_page, after: $endCursor, ownerAffiliations: OWNER) {
      nodes {
        name
        refs(refPrefix: "refs/tags/", last: 100) {
          nodes { name }
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
"""

def build_index(path_glob, output_path):
    result = OrderedDict({
        'packs': OrderedDict(),
        'metadata': OrderedDict([
            ('generated_ts', None),  # Timestamp of when the file has been generated
            ('hash', None)  # MD5 hash of all the content, useful when mirror the index
        ])
    })

    data_hash = hashlib.md5()

    path_glob = os.path.expanduser(path_glob)
    generator = sorted(glob(path_glob))

    counter = 0
    failed_count = 0
    for filename in generator:
        with open(filename, 'r') as pack:
            pack_meta = yaml.safe_load(pack)

        pack_name = pack_meta['name']
        pack_ref = get_pack_ref_from_metadata(metadata=pack_meta)
        sanitized_pack_name = pack_ref

        print('Processing pack: %s (%s)' % (pack_name, filename))

        pack_meta['repo_url'] = 'https://github.com/%s/%s-%s' % (
            EXCHANGE_NAME, EXCHANGE_PREFIX, sanitized_pack_name
        )

        versions = get_available_versions_for_pack(pack_ref)

        if versions is None:
            failed_count += 1

        if versions is not None:
            pack_meta['versions'] = versions

        # Note: Key in the index dictionary is ref and not a name
        result['packs'][pack_ref] = pack_meta

        # Remove any old entry for pack name when we incorrectly used name instead of ref for the
        # key
        if pack_name != pack_ref:
            result['packs'].pop(pack_name, None)

        if six.PY2:
            data_hash.update(str(pack_meta))
        else:
            data_hash.update(str(pack_meta).encode('utf-8'))
        counter += 1

    result['metadata']['generated_ts'] = int(time.time())
    result['metadata']['hash'] = data_hash.hexdigest()

    output_path = os.path.expanduser(os.path.join(output_path, 'index.json'))
    with open(output_path, 'w') as outfile:
        json.dump(result, outfile, indent=4, sort_keys=True,
                  separators=(',', ': '))

    failed_message = ''
    if failed_count > 0:
        failed_message = (
            ', {failed_count} packs failed to update.\n'
            'The GitHub Personal Access Tokens for CircleCI for the pack may '
            'need to be refreshed.\n'
            '\n'
            'See the tools/reset_github_user_token_and_update_circleci.sh script in\n'
            '  https://github.com/{exchange_name}/ci\n'
            '\n'
            'If you do not have the necessary GitHub and CircleCI credentials, you\n'
            'will need to ask a member of the StackStorm TSC to update the Personal\n'
            'Access Token on your behalf.'
        ).format(failed_count=failed_count, exchange_name=EXCHANGE_NAME)

    print('')
    print('Processed %s packs%s.' % (counter, failed_message))
    print('Index data written to "%s".' % (output_path))


def get_available_versions():
    """
    Retrieve all the available versions for all packs

    NOTE: This function uses Github API.
    """
    pages = []

    # use `gh` to handle getting all pages
    proc = subprocess.Popen(
        [
            "gh", "api", "--paginate", "graphql",
            "-f", "owner=" + EXCHANGE_NAME,
            "-f", "query=" + GQL_PACK_TAGS_QUERY,
        ],
        env={"GH_TOKEN": GITHUB_PASSWORD},
        stdout=subprocess.PIPE,
    )
    # This should never take more than 5 seconds.
    # If network is really bad, let it go for 30.
    try:
        outs, _ = proc.communicate(timeout=30)
    except subprocess.TimeoutExpired:
        proc.kill()
        outs, _ = proc.communicate()
    result = outs.decode().strip()

    # https://stackoverflow.com/a/43807246/1134951
    decoder = json.JSONDecoder()
    pos = 0
    len_result = len(result)
    while pos < len_result:
        j, json_len = decoder.raw_decode(result, idx=pos)
        pos += json_len
        pages.append(j)

    # PREFIX-<pack name>
    prefix_len = len(EXCHANGE_PREFIX) + 1

    for page in pages:
        repos = page["data"]["repositoryOwner"]["repositories"]["nodes"]
        packs = [
            {
                "reponame": repo["name"],
                "tags": [tag["name"] for tag in repo["refs"]["nodes"]]
            } for repo in repos if repo["name"].startswith(EXCHANGE_PREFIX)
        ]
        for pack in packs:
            pack_name = pack["reponame"][prefix_len:]
            PACK_VERSIONS.setdefault(pack_name, []).extend(
                tag.replace("v", "") for tag in pack["tags"]
                if tag.startswith("v")  # only version tags
            )


def get_available_versions_for_pack(pack_ref):
    """
    Retrieve all the available versions for a particular pack.

    NOTE: This function uses Github API.
    """
    if pack_ref not in PACK_VERSIONS:
        url = ('https://api.github.com/repos/%s/%s-%s/tags' %
               (EXCHANGE_NAME, EXCHANGE_PREFIX, pack_ref))
        resp = SESSION.get(url)

        if resp.status_code != 200:
            print('Got non 200 response: %s' % (resp.text))
            return None

        versions = []

        for item in resp.json():
            if item.get('name', '').startswith('v'):
                versions.append(item['name'].replace('v', ''))
    else:
        versions = PACK_VERSIONS[pack_ref]

    versions = list(reversed(sorted(set(versions))))

    return versions


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate StackStorm exchange index.json')
    parser.add_argument('--glob', help='Glob which points to the pack metadatafiles',
                        required=True)
    parser.add_argument('--output', help='Directory where the generated index.json file is stored',
                        required=True)
    args = parser.parse_args()

    get_available_versions()
    build_index(path_glob=args.glob, output_path=args.output)
