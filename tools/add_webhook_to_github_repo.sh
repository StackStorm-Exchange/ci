#!/usr/bin/env bash

# Script which adds a new webhook to the provided github repo.
#
# Requires: jq
#
# The following env variables must be specified:
# * USERNAME: a GitHub user to run the script under (Exchange bot).
# * PASSWORD: password for the user (not a token).
# * REPO_NAMES: If specified only force build for specified repo(s) otherwise force it for
#               all the repos.

set -e

# Include script with common functionality
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_PATH}/common.sh"

if [[ ! $# -eq 1 ]];
then
    echo "Usage: $0 <webhook url>"
    exit 1;
fi

WEBHOOK_URL="$1"

if [[ ! -z "${REPO_NAMES}" ]]; then
  OIFS=$IFS;
  IFS=" "
  REPO_NAMES=($REPO_NAMES)
  IFS=$OIFS;
else
  get_all_exchange_repo_names "${EXCHANGE_ORG}" "${EXCHANGE_PREFIX}"
fi

for REPO_NAME in ${REPO_NAMES[@]}; do
    echo "Adding webhook "${WEBHOOK_URL}" to repo: ${REPO_NAME}"
    # Github: Configure webhook
    curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST --header "Content-Type: application/json" \
        -d '{"name": "web", "active": true, "config": {"url": "'"${WEBHOOK_URL}"'", "content_type": "application/json"}, "events": ["commit_comment", "issue_comment", "issues", "pull_request", "pull_request_review", "pull_request_review_comment"]}' \
        "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_NAME}/hooks"
    sleep ${SLEEP_DELAY}
done
