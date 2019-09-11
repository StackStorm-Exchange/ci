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

import sys
import re

import validate

SEMVER_REGEX = "^(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-[\da-z\-]+(?:\.[\da-z\-]+)*)?(?:\+[\da-z\-]+(?:\.[\da-z\-]+)*)?$"
SINGLE_VERSION_REGEX = "^\d+$"
DOUBLE_VERSION_REGEX = "^\d+\.\d+$"


def get_semver_string(version):
    if re.match(SINGLE_VERSION_REGEX, str(version)):
        return "%s.0.0" % version
    elif re.match(DOUBLE_VERSION_REGEX, str(version)):
        return "%s.0" % version
    elif re.match(SEMVER_REGEX, version):
        return version
    else:
        raise ValueError("Cannot convert %s to semver." % version)

if __name__ == '__main__':
    pack = validate.load_yaml_file(sys.argv[1])
    print(get_semver_string(pack['version']))
