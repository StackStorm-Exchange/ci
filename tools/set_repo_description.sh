#!/usr/bin/env bash

# Script which sets pack Github repo description so it matches "description"
#
# Requires: jq
#
# attribute from pack.yaml metadata file.
# * USERNAME: a GitHub user to run the script under (Exchange bot).
# * PASSWORD: password for the user (not a token).
# * REPO_NAMES: If specified only set description for specified repo(s)
#               otherwise set it for all the repos.

set -e

# Include script with common functionality
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_PATH}/common.sh"

if [[ -n "${REPO_NAMES}" ]]; then
  OIFS=$IFS;
  IFS=" "
  REPO_NAMES=($REPO_NAMES)
  IFS=$OIFS;
else
  get_all_exchange_repo_names "${EXCHANGE_ORG}" "${EXCHANGE_PREFIX}"
fi

for REPO_NAME in ${REPO_NAMES[@]}; do
    echo "Setting description for repo: ${REPO_NAME}"

    # Retrieve description from pack.yaml
    PACK_YAML_URL="https://raw.githubusercontent.com/StackStorm-Exchange/${REPO_NAME}/master/pack.yaml"
    PACK_DESCRIPTION=$(curl -sS --fail -X GET "${PACK_YAML_URL}" | python -c 'import yaml,sys; c=yaml.safe_load(sys.stdin);print c["description"]')

    if [[ -z "${PACK_DESCRIPTION}" ]]; then
        echo "Description not available for pack ${REPO_NAME}, skipping..."
    else
        curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X PATCH --header "Content-Type: application/json" \
        -d '{"name": "'"${REPO_NAME}"'", "description": "'"${PACK_DESCRIPTION}"'", "homepage": "https://exchange.stackstorm.org/"}' \
        "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_NAME}"

        sleep ${SLEEP_DELAY}
    fi
done
