#!/bin/bash
#
# A helper script to bootstrap a new StackStorm Exchange pack.
# Creates tokens and keys, commits circle.yml for CI, adds the
# project to CircleCI.
#
# The script will create a repo with circle.yml, and the initial
# contents of the pack should be then submitted as a PR to perform
# linting and test run. After the PR is merged, the index will
# be updated, and version tags will be inferred from commit history.
#
# Requires: jq
#
# The following env variables must be specified:
# * USERNAME: a GitHub user to run the script under (Exchange bot).
# * PASSWORD: password for the user (not a token).
# * CIRCLECI_TOKEN: a CircleCI token for the Exchange organization.
#

set -e

if [ ! $# -eq 1 ];
then
    echo "Usage: $0 <pack>"
    exit 1;
fi

PACK="$1"
EXCHANGE_ORG="${EXCHANGE_ORG:-StackStorm-Exchange}"
EXCHANGE_PREFIX="${EXCHANGE_PREFIX:-stackstorm}"
REPO_NAME="${EXCHANGE_PREFIX}-${PACK}"
REPO_DIR="/tmp/${REPO_NAME}"
REPO_URL="https://${USERNAME}:${PASSWORD}@github.com/${EXCHANGE_ORG}/${REPO_NAME}"

# Check if the repo exists

if git ls-remote ${REPO_URL} > /dev/null 2>&1;
then
    echo "The repository already exists, cannot bootstrap."
    exit 1
fi

# Git: create an empty repo and set the remote
rm -rf ${REPO_DIR} /tmp/${PACK}_rsa* /tmp/${PACK}_user_token
mkdir ${REPO_DIR} && cd ${REPO_DIR}
git init && git remote add origin ${REPO_URL}

# Generate a keypair
ssh-keygen -b 2048 -t rsa -f /tmp/${PACK}_rsa -q -N ""

# GitHub: create a repo
curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST --header "Content-Type: application/json" \
    -d '{"name": "'"${REPO_NAME}"'"}' \
    "https://api.github.com/orgs/${EXCHANGE_ORG}/repos"

# GitHub: create a read-write key for the repo
curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST --header "Content-Type: application/json" \
    -d '{"title": "CircleCI read-write key", "key": "'"$(cat /tmp/${PACK}_rsa.pub)"'", "read_only": false}' \
    "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_NAME}/keys"

# GitHub: create a user-scope token
curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST --header "Content-Type: application/json" \
    -d '{"scopes": ["public_repo"], "note": "CircleCI: '"${REPO_NAME}"'"}' \
    "https://api.github.com/authorizations" | jq ".token" > /tmp/${PACK}_user_token

if [ ! -s /tmp/${PACK}_user_token ];
then
    echo "Could not create a token."
    exit 1
fi

# Git: push circle.yml
curl -sS --fail "https://raw.githubusercontent.com/StackStorm-Exchange/ci/master/.circle/circle.yml.sample" > circle.yml
chmod 755 circle.yml
git add circle.yml
git commit -m 'Bootstrap a StackStorm Exchange pack repository.'
git push origin master

# CircleCI: follow the project
curl -sS --fail -X POST "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/follow?circle-token=${CIRCLECI_TOKEN}"

# CircleCI: upload the read-write key
curl -sS --fail -X POST --header "Content-Type: application/json" \
    -d '{"hostname":"github.com","private_key":"'"$(cat /tmp/${PACK}_rsa)"'"}' \
    "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/ssh-key?circle-token=${CIRCLECI_TOKEN}"

# CircleCI: specify the credentials (the machine login and the new user-scope token)
curl -sS --fail -X POST --header "Content-Type: application/json" \
    -d '{"name":"MACHINE_USER", "value":"'"${USERNAME}"'"}' \
    "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"
curl -sS --fail -X POST --header "Content-Type: application/json" \
    -d '{"name":"MACHINE_PASSWORD", "value":'"$(cat /tmp/${PACK}_user_token)"'}' \
    "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"

# Clean up
rm -rf ${REPO_DIR} /tmp/${PACK}_rsa* /tmp/${PACK}_user_token
