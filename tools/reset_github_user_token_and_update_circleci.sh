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

if [[ ! $# -gt 0 ]];
then
    echo "Usage: $0 <pack> [<pack> <pack> ...]"
    exit 1
fi

BROWSER_NAME=firefox
BROWSER="/Applications/Firefox.app/Contents/MacOS/firefox -private-window"

EXCHANGE_ORG="${EXCHANGE_ORG:-StackStorm-Exchange}"
EXCHANGE_PREFIX="${EXCHANGE_PREFIX:-stackstorm}"

function repo_name() {
    local pack="$1"
    local repo_name=""
    # Add the stackstorm- prefix to the repo name if it doesn't exist already
    if [[ "$pack" = ${EXCHANGE_PREFIX}-* ]];
    then
        repo_name="$pack"
    else
        repo_name="${EXCHANGE_PREFIX}-${pack}"
    fi
    echo ${repo_name}
}

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
echo "Github: Creating a Github user-scoped token for each pack"
echo

for PACK in $@; do
    REPO_NAME=$(repo_name ${PACK})
    echo "REPO_NAME=${REPO_NAME}"
    echo

    echo "Please click 'Generate Token' when ${BROWSER_NAME} opens."
    echo "Then copy the Github PAT token and paste it here:"
    ${BROWSER} "https://github.com/settings/tokens/new?scopes=public_repo&description=CircleCI%3A%20${REPO_NAME}"
    read -s GITHUB_USER_TOKEN

    if [[ -z "$GITHUB_USER_TOKEN" ]];
    then
        echo "Could not create a GitHub Personal Access Token."
        exit 1
    fi

    echo "GitHub Personal Access Token for ${USERNAME}:"
    echo
    echo "    ${GITHUB_USER_TOKEN}"
    echo

    # CircleCI: specify the credentials (the machine login and the new user-scope token)
    echo "CircleCI: Setting credentials (machine login and user-scoped token)"
    curl -sS --fail -X POST --header "Content-Type: application/json" \
        -d '{"name":"MACHINE_USER", "value":"'"${USERNAME}"'"}' \
        "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"
    curl -sS --fail -X POST --header "Content-Type: application/json" \
        -d '{"name":"MACHINE_PASSWORD", "value": "'"${GITHUB_USER_TOKEN}"'"}' \
        "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"
done
