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
    print("---> load_yaml_file(sys.argv[2]) START")#debug
    with open(path, 'r') as stream:
        text = yaml.safe_load(stream)
    
    print("text="+text)
    return text


def validate_schema(instance, schema):
    print("---> validate_schema(instance, schema): START")
    return util_schema.validate(instance=instance, schema=schema,
                                cls=util_schema.CustomValidator,
                                use_default=True,
                                allow_default_none=True)


def validate_pack_contains_valid_ref_or_name(pack_meta):
    print("---> validate_pack_contains_valid_ref_or_name(pack_meta) START")
    ref = get_pack_ref_from_metadata(metadata=pack_meta)
    return ref


def validate_repo_name(instance, repo_name):
    print("---> validate_repo_name(instance, repo_name) START")
    if '%s-%s' % (PREFIX, instance['name']) != repo_name:
        raise ValueError('Pack name is different from repository name.')


if __name__ == '__main__':
    print("---> validate.py START")#debug
    print("sys.argv[1]="+sys.argv[1])#debug
    print("sys.argv[2]="+sys.argv[2])#debug
    repo_name = sys.argv[1]
    print("repo_name="+repo_name)#debug
    pack_meta = load_yaml_file(sys.argv[2])
    print("---> pack_meta = load_yaml_file(sys.argv[2]) END")#debug
    print("pack_meta="+pack_meta)#debug

    # TODO: Figure out why this wasn't previously executed, and execute it
    # validate_repo_name(pack_meta, repo_name)
    valreturn = validate_schema(pack_meta, PACK_SCHEMA)
    print("---> load_yaml_file(sys.argv[2]) END")#debug
    print("valreturn=" + valreturn)#debug
    pack_ref = validate_pack_contains_valid_ref_or_name(pack_meta)
    print("---> pack_ref = validate_pack_contains_valid_ref_or_name(pack_meta) END")

    print(pack_ref)
    print("---> validate.py END")
