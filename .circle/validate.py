# Licensed to the StackStorm, Inc ('StackStorm') under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
from __future__ import print_function

import sys

import yaml

from st2common.models.api.pack import PackAPI
from st2common.util import schema as util_schema
from st2common.util.pack import get_pack_ref_from_metadata

PREFIX = 'stackstorm'
PACK_SCHEMA = PackAPI.schema


def load_yaml_file(path):
    with open(path, 'r') as stream:
        text = yaml.safe_load(stream)
    
    return text


def validate_schema(instance, schema):
    return util_schema.validate(instance=instance, schema=schema,
                                cls=util_schema.CustomValidator,
                                use_default=True,
                                allow_default_none=True)


def validate_pack_contains_valid_ref_or_name(pack_meta):
    ref = get_pack_ref_from_metadata(metadata=pack_meta)
    return ref


def validate_repo_name(instance, repo_name):
    if '%s-%s' % (PREFIX, instance['name']) != repo_name:
        raise ValueError('Pack name is different from repository name.')


if __name__ == '__main__':
    pack_path = sys.argv[1]
    repo_name = sys.argv[2]
    pack_yaml_path = pack_path + "/" + repo_name + "/" + "pack.yaml"
   
    pack_meta = load_yaml_file(pack_yaml_path)
    validate_repo_name(pack_meta, repo_name)
    validate_schema(pack_meta, PACK_SCHEMA)
    pack_ref = validate_pack_contains_valid_ref_or_name(pack_meta)
    
    print(pack_ref)
