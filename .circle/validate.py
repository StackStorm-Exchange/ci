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

import os
import sys

import yaml

from st2common.models.api.pack import PackAPI
from st2common.util import schema as util_schema
from st2common.util.pack import get_pack_ref_from_metadata

PREFIX = os.environ.get("PACKS_PREFIX", "stackstorm")
PACK_SCHEMA = PackAPI.schema


def load_yaml_file(path):
    with open(path, "r", encoding="utf8") as stream:
        text = yaml.safe_load(stream)

    return text


def validate_schema(instance, schema):
    # validate() returns a cleaned instance with default values assigned.
    # and it calls jsonschema.validate(instance, schema) so this will
    # raise ValidationError if instance is not valid according to schema
    return util_schema.validate(
        instance=instance,
        schema=schema,
        cls=util_schema.CustomValidator,
        use_default=True,
        allow_default_none=True,
    )


def validate_pack_contains_valid_ref_or_name(pack_meta):
    ref = get_pack_ref_from_metadata(metadata=pack_meta)
    return ref


def validate_repo_name(instance, repo_name):
    if f"{PREFIX}-{instance['name']}" != repo_name:
        raise ValueError("Pack name is different from repository name.")


if __name__ == "__main__":
    # If an exception is raised, python basically does sys.exit(1)
    # Without an exception, the return code is 0.

    repo_name = sys.argv[1]
    # raises if yaml is invalid
    pack_meta = load_yaml_file(sys.argv[2])

    # TODO: Figure out why this wasn't previously executed, and execute it
    #       stackstorm-test-content-version repo is test_content_version pack
    #       stackstorm-test2 repo is test pack
    # validate_repo_name(pack_meta, repo_name)

    # raises ValidationError if pack_meta doesn't validate against PACK_SCHEMA
    cleaned_pack_meta = validate_schema(pack_meta, PACK_SCHEMA)

    # raises ValueError if pack ref not defined and pack name is not a valid ref
    pack_ref = validate_pack_contains_valid_ref_or_name(pack_meta)

    print(pack_ref)
