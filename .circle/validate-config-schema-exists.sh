#!/usr/bin/env bash
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

PACK_PATH=$1

if [ ! "${PACK_PATH}" ]; then
    echo "Usage: $0 <pack path>"
    exit 1
fi

if [ ! -d "${PACK_PATH}" ]; then
    echo "Pack directory ${PACK_PATH} doesn't exist"
    exit 1
fi

if [ ! -f "${PACK_PATH}/config.schema.yaml" ]; then
    echo "Pack ${PACK_PATH} is missing config.schema.yaml file"
    exit 2
fi

if [ -f "${PACK_PATH}/config.yaml" ]; then
    echo "Pack ${PACK_PATH} contains config.yaml file which has been deprecated and replaced with config.schema.yaml"
    exit 2
fi

exit 0
