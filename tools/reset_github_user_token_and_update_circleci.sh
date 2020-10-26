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
# Add the stackstorm- prefix to the repo name if it doesn't exist already
if [[ "$PACK" = ${EXCHANGE_PREFIX}-* ]];
then
    REPO_NAME="$PACK"
else
    REPO_NAME="${EXCHANGE_PREFIX}-${PACK}"
fi

DEFAULT_USERNAME="stackstorm-neptr"
if [[ -z "$USERNAME" ]];
then
    echo "What is the username for the GitHub user?"
    echo "Default: $DEFAULT_USERNAME (just hit enter to use this)"
    read USERNAME
    USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
fi

if [[ -z "$PASSWORD" ]];
then
    echo "What is the password for the GitHub user (${USERNAME})?"
    echo "This password is stored in LastPass under the ${DEFAULT_USERNAME}"
    echo "account."
    read -s PASSWORD
fi

if [[ -z "$CIRCLECI_TOKEN" ]];
then
    echo "What is the CircleCI token for the ${EXCHANGE_ORG}?"
    echo "This token is stored in LastPass in the notes section under the "
    echo "${DEFAULT_USERNAME} for GitHub."
    read -s CIRCLECI_TOKEN
fi

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
