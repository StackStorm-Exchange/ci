#!/usr/bin/env bash
#
# Script which triggers Circle CI builds for all the exchange repos for master
# branch.
#
# Requires: jq
#
# The following env variables must be specified:
# * CIRCLECI_TOKEN: a CircleCI token for the Exchange organization.

set -e

EXCHANGE_ORG="${EXCHANGE_ORG:-StackStorm-Exchange}"
EXCHANGE_PREFIX="${EXCHANGE_PREFIX:-stackstorm}"
SLEEP_DELAY="${SLEEP_DELAY:-2}"

if [ ! ${CIRCLECI_TOKEN} ]; then
  echo "CIRCLECI_TOKEN environment variable not set"
  exit 2
fi

# 1. List all Github repos for the org
REPO_NAMES=$(curl -sS --fail -X GET "https://api.github.com/orgs/${EXCHANGE_ORG}/repos?per_page=1000" \
    | jq --raw-output ".[].name")

OIFS=$IFS;
IFS=" "
REPO_NAMES=($REPO_NAMES)
IFS=$OIFS;

# 2. Filter out non pack repos
REPO_NAMES=( $(for i in ${REPO_NAMES[@]} ; do echo $i ; done | grep "${EXCHANGE_PREFIX}-") )

# 3. Trigger Circle CI build for each pack
for REPO_NAME in ${REPO_NAMES[@]}; do
  echo "Triggering CircleCI build for repo / pack: ${REPO_NAME}"

  curl \
    --header "Content-Type: application/json" \
    --request POST \
    https://circleci.com/api/v1/project/${EXCHANGE_ORG}/${REPO_NAME}/tree/master?circle-token=${CIRCLECI_TOKEN}
  echo ""
  echo "Build page at: "https://circleci.com/gh/${EXCHANGE_ORG}/${REPO_NAME}
  sleep ${SLEEP_DELAY}
done
