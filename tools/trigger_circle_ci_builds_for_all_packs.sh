#!/usr/bin/env bash
#
# Script which triggers Circle CI builds for all the exchange repos for master
# branch.
#
# Requires: jq
#
# The following env variables must be specified:
# * CIRCLECI_TOKEN: a CircleCI token for the Exchange organization.
# * REPO_NAMES: If specified only force build for specified repo(s) otherwise force it for
#               all the repos/
# * FORCE_REBUILD_INDEX: Set it to "1" to force index rebuild.

set -e

# Include script with common functionality
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_PATH}/common.sh"

FORCE_REBUILD_INDEX="${FORCE_REBUILD_INDEX:-0}"

if [[ ! ${CIRCLECI_TOKEN} ]]; then
  echo "CIRCLECI_TOKEN environment variable not set"
  exit 2
fi

if [[ ! -z "${REPO_NAMES}" ]]; then
  # Only force build for provided repos
  OIFS=$IFS;
  IFS=" "
  REPO_NAMES=($REPO_NAMES)
  IFS=$OIFS;
else
  # Force build for all pack repos
  get_all_exchange_repo_names "${EXCHANGE_ORG}" "${EXCHANGE_PREFIX}"
fi

# Trigger Circle CI build for each pack
for REPO_NAME in ${REPO_NAMES[@]}; do
  echo "Triggering CircleCI build for repo / pack: ${REPO_NAME}"

  CIRCLE_TRIGGER_BUILD_URL="https://circleci.com/api/v1/project/${EXCHANGE_ORG}/${REPO_NAME}/tree/master?circle-token=${CIRCLECI_TOKEN}"

  if [[ ${FORCE_REBUILD_INDEX} == "1" ]]; then
    curl \
      --header "Content-Type: application/json" \
      --request POST \
      --data '{"build_parameters": {"FORCE_REBUILD_INDEX": "1"}}' \
      ${CIRCLE_TRIGGER_BUILD_URL}
  else
    curl \
      --header "Content-Type: application/json" \
      --request POST \
      ${CIRCLE_TRIGGER_BUILD_URL}
  fi

  echo ""
  echo "Build page at: "https://circleci.com/gh/${EXCHANGE_ORG}/${REPO_NAME}
  sleep ${SLEEP_DELAY}
done
