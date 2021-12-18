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

import json
import sys
import typing

import yaml


def load_yaml_file(path):
    with open(path, "r", encoding="utf8") as stream:
        text = yaml.safe_load(stream)

    return text


def dump(value):
    if isinstance(value, typing.Collection):
        value = json.dumps(value)
    # else it is a simple int or str (pass as is w/o json quotes)
    return value


if __name__ == "__main__":
    pack = load_yaml_file(sys.argv[1])
    key = sys.argv[2]
    value = pack.get(key, "")
    print(dump(value))
