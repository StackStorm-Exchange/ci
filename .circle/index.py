import json
import yaml
import sys
import time
import hashlib
from glob import glob
from collections import OrderedDict

EXCHANGE_NAME = "StackStorm-Exchange"
EXCHANGE_PREFIX = "stackstorm"


def build_index(path):
    result = OrderedDict({
        'packs': OrderedDict(),
        'metadata': OrderedDict({
            'generated_ts': None,  # Timestamp of when the file has been generated
            'hash': None  # MD5 hash of all the content, useful when mirror the index
        })
    })

    data_hash = hashlib.md5()

    generator = sorted(glob('%s/packs/*.yaml' % path))
    for filename in generator:
        with open(filename, 'r') as pack:
            pack_meta = yaml.load(pack)

        pack_meta['repo_url'] = 'https://github.com/%s/%s-%s' % (
            EXCHANGE_NAME, EXCHANGE_PREFIX, pack_meta['name']
        )
        result['packs'][pack_meta['name']] = pack_meta
        data_hash.update(str(pack_meta))

    result['metadata']['generated_ts'] = int(time.time())
    result['metadata']['hash'] = data_hash.hexdigest()

    with open('%s/index.json' % path, 'w') as outfile:
        json.dump(result, outfile, indent=4, sort_keys=True)

if __name__ == '__main__':
    path = sys.argv[1]
    build_index(path)
