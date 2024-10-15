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
import re
import yaml

SEMVER_REGEX = re.compile(
    r"""^(?:0|[1-9]\d*)
                              \.
                              (?:0|[1-9]\d*)
                              \.
                              (?:0|[1-9]\d*)
                              (?:-[\da-z\-]+(?:\.[\da-z\-]+)*)?
                              (?:\+[\da-z\-]+(?:\.[\da-z\-]+)*)?$""",
    re.VERBOSE,
)
SINGLE_VERSION_REGEX = re.compile(r"^\d+$")
DOUBLE_VERSION_REGEX = re.compile(r"^\d+\.\d+$")


def load_yaml_file(path):
    with open(path, "r", encoding="utf8") as stream:
        text = yaml.safe_load(stream)

    return text


def get_semver_string(version):
    if SINGLE_VERSION_REGEX.match(str(version)):
        semver = f"{version}.0.0"
    elif DOUBLE_VERSION_REGEX.match(str(version)):
        semver = f"{version}.0"
    elif SEMVER_REGEX.match(version):
        semver = version
    else:
        raise ValueError(f"Cannot convert {version} to semver.")
    return semver


if __name__ == "__main__":
    pack = load_yaml_file(sys.argv[1])
    print(get_semver_string(pack["version"]))
