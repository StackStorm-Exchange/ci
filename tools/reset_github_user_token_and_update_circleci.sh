#!/bin/bash

# Script which resets Github user token for a pack (repo) and submits new token info to
# Circle CI
#
# Requires: jq
#
# The following env variables must be specified:
# * USERNAME: a GitHub user to run the script under (Exchange bot).
# * PASSWORD: password for the user (not a token).
# * CIRCLECI_TOKEN: a CircleCI token for the Exchange organization.
#

if [[ ! $# -eq 1 ]];
then
    echo "Usage: $0 <pack>"
    exit 1
fi

PACK="$1"
EXCHANGE_ORG="${EXCHANGE_ORG:-StackStorm-Exchange}"
EXCHANGE_PREFIX="${EXCHANGE_PREFIX:-stackstorm}"
REPO_NAME="${EXCHANGE_PREFIX}-${PACK}"

# GitHub: create a user-scope token
# TODO: Delete any existing token for that repo
echo "Github: Creating a Github user-scoped token"
curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST --header "Content-Type: application/json" \
    -d '{"scopes": ["public_repo"], "note": "CircleCI: '"${REPO_NAME}"'"}' \
    "https://api.github.com/authorizations" | jq ".token" > "/tmp/${PACK}_user_token"

if [[ ! -s "/tmp/${PACK}_user_token" ]];
then
    echo "Could not create a token."
    exit 1
fi

# CircleCI: specify the credentials (the machine login and the new user-scope token)
echo "CircleCI: Setting credentials (machine login and user-scoped token)"
curl -sS --fail -X POST --header "Content-Type: application/json" \
    -d '{"name":"MACHINE_USER", "value":"'"${USERNAME}"'"}' \
    "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"
curl -sS --fail -X POST --header "Content-Type: application/json" \
    -d '{"name":"MACHINE_PASSWORD", "value":'"$(cat "/tmp/${PACK}_user_token")"'}' \
    "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"
