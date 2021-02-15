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
# * SLACK_WEBHOOK_URL: Full URL to Slack webhook where GitHub event notifications will be sent.
# * GITHUB_PACK_PAT: GitHub Personal Access Token for the stackstorm-neptr user
#                    (url: https://github.com/settings/tokens)
#                    that has a name "CircleCI: stackstorm-<pack>" and given
#                    the 'public_repo" scope. This PAT is used by CircleCI to access
#                    the repo.
#
# Optionally, this env variable can be set to send additional GitHub event notifications
# * SLACK_WEBHOOK_URL_COMMUNITY
set -e

if [[ ! $# -eq 1 ]];
then
  echo "Usage: $0 <pack>"
  exit 1;
fi

EXCHANGE_ORG="${EXCHANGE_ORG:-StackStorm-Exchange}"
EXCHANGE_PREFIX="${EXCHANGE_PREFIX:-stackstorm}"
PACK="${1/${EXCHANGE_PREFIX}-/}"  # Ensure that PACK is just the bare pack name
REPO_ALIAS=${PACK}
REPO_NAME="${EXCHANGE_PREFIX}-${PACK}"
REPO_DIR="/tmp/${REPO_NAME}"
REPO_URL="https://${USERNAME}:${PASSWORD}@github.com/${EXCHANGE_ORG}/${REPO_NAME}"
ALIAS_URL="https://${USERNAME}:${PASSWORD}@github.com/${EXCHANGE_ORG}/${REPO_ALIAS}"

# Generating GitHub PAT (personal access tokens) can no longer be done via the API
# broken: https://developer.github.com/changes/2/#--deprecating-oauth-authorization-api
if [ -z "${GITHUB_PACK_PAT}" ]; then
  echo "GitHub disabled the API allowing us to generate Personal Access Tokens for users"
  echo "Please perform the following steps:"
  echo "  1) login to GitHub as the 'stackstorm-neptr' account"
  echo "  2) visit: https://github.com/settings/tokens"
  echo "  3) click 'Genearte new token'"
  echo "    3a) Note: CircleCI: ${REPO_NAME}"
  echo "    3b) Select scopes: public_repo"
  echo "    3c) Generate token"
  echo "  4) Copy the new token and export it as the GITHUB_PACK_PAT shell variable"
  echo "     export GITHUB_PACK_PAT='b4d3xxx'"
  echo "  5) Re-run this script"
fi


# Check if the repo exists

if git ls-remote "${REPO_URL}" > /dev/null 2>&1;
then
  echo "The repository already exists, cannot bootstrap."
  exit 1
fi

# Git: create an empty repo and set the remote
rm -rf "${REPO_DIR}" "/tmp/${PACK}_rsa*" "/tmp/${PACK}_user_token"
mkdir "${REPO_DIR}" && cd "${REPO_DIR}"
git init && git remote add origin "${REPO_URL}"

# Generate a keypair
echo "Generating random private SSH key"
ssh-keygen -b 2048 -t rsa -f "/tmp/${PACK}_rsa" -q -N "" -m pem

# GitHub: create a repo or create an alias and move
if git ls-remote "${ALIAS_URL}" > /dev/null 2>&1;
then
  echo "The alias already exists, skipping the creation."
else
  echo "Creating an alias ${REPO_ALIAS} for ${REPO_NAME}."
  curl -v -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST \
       --header "Content-Type: application/json" \
       -d '{"name": "'"${REPO_ALIAS}"'"}' \
       "https://api.github.com/orgs/${EXCHANGE_ORG}/repos"
fi

# GitHub: rename the alias repo to its full name
echo "GitHub: Renaming the repo to ${REPO_NAME}."
curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X PATCH \
     --header "Content-Type: application/json" \
     -d '{"name": "'"${REPO_NAME}"'"}' \
     "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_ALIAS}"

# GitHub: create a read-write key for the repo
echo "GitHub: Creating a read-write key for the GitHub repo"
curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST \
     --header "Content-Type: application/json" \
     -d '{"title": "CircleCI read-write key", "key": "'"$(cat "/tmp/${PACK}_rsa.pub")"'", "read_only": false}' \
     "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_NAME}/keys"

# GitHub: create a user-scope token
echo -n "${GITHUB_PACK_PAT}" > "/tmp/${PACK}_user_token"
if [[ ! -s "/tmp/${PACK}_user_token" ]];
then
  echo "Could not find a GitHub Personal Access Token, the shell variable GITHUB_PACK_PAT is empty"
  exit 1
fi

# Git: push - add various files which are needed to bootstrap the repo:
# - circle.yml
# - .gitignore
mkdir -p .circleci
curl -sS --fail "https://raw.githubusercontent.com/StackStorm-Exchange/ci/master/.circle/circle.yml.sample" > .circleci/config.yml
chmod 755 .circleci/config.yml
git add .circleci/config.yml

curl -sS --fail "https://raw.githubusercontent.com/StackStorm-Exchange/ci/master/files/.gitignore.sample" > .gitignore
git add .gitignore

git commit -m "Bootstrap a StackStorm Exchange pack repository for pack ${PACK}."
git push origin master

# GitHub: Configure webhook to send notifications to our Slack instance on changes
echo "GitHub: Configuring GitHub to send webhook notifications to our Slack"
curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST \
     --header "Content-Type: application/json" \
     -d '\
     { \
       "name": "web", \
       "active": true, \
       "config": { \
         "url": "'"${SLACK_WEBHOOK_URL}"'", \
         "content_type": "application/json" \
       }, \
       "events": [ \
         "commit_comment", \
         "issue_comment", \
         "issues", \
         "pull_request", \
         "pull_request_review", \
         "pull_request_review_comment" \
       ] \
     }' \
     "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_NAME}/hooks"

# GitHub: If second Slack webhook URL set (e.g. for community), configure that to notify on changes
if [[ -n $SLACK_WEBHOOK_URL_COMMUNITY ]];
then
  echo "GitHub: Configuring GitHub to send webhook notifications to our community Slack"
  curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X POST \
       --header "Content-Type: application/json" \
       -d '\
       { \
         "name": "web", \
         "active": true, \
         "config": { \
           "url": "'"${SLACK_WEBHOOK_URL_COMMUNITY}"'", \
           "content_type": "application/json" \
         }, \
         "events": [ \
           "issues", \
           "pull_request" \
         ] \
       }' \
       "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_NAME}/hooks"
fi

# NO longer needed, this API request fails everytime we call it
# # CircleCI: follow the project
# echo "CircleCI: Following the project"
# curl -v -sS --fail -X POST \
#      --header "Circle-Token: ${CIRCLECI_TOKEN}" \
#      "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/follow"


# CircleCI: upload the read-write key
echo "CircleCI: Adding read-write SSH key"
curl -sS --fail -X POST --header "Content-Type: application/json" \
     --header "Circle-Token: ${CIRCLECI_TOKEN}" \
     -d '{"hostname":"github.com","private_key":"'"$(cat "/tmp/${PACK}_rsa")"'"}' \
     "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/ssh-key"

# CircleCI: specify the credentials (the machine login and the new user-scope token)
echo "CircleCI: Setting credentials (machine login and user-scoped token)"
curl -sS --fail -X POST --header "Content-Type: application/json" \
     --header "Circle-Token: ${CIRCLECI_TOKEN}" \
     -d '{"name":"MACHINE_USER", "value":"'"${USERNAME}"'"}' \
     "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar"
curl -sS --fail -X POST --header "Content-Type: application/json" \
     --header "Circle-Token: ${CIRCLECI_TOKEN}" \
     -d '{"name":"MACHINE_PASSWORD", "value":"'"$(cat "/tmp/${PACK}_user_token")"'"}' \
     "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar"

# CircleCI: Enable builds for pull requests from forks
echo "CircleCI: Enabling builds for pull requests from forks"
curl -sS --fail -X PUT --header "Content-Type: application/json" \
     --header "Circle-Token: ${CIRCLECI_TOKEN}" \
     -d '{"feature_flags":{"build-fork-prs":true}}' \
     "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/settings"

# CircleCI has started automatically adding a read-only deploy key when following a project
# This breaks our deployment process.
# So we need to get a list of read-only keys, and delete them
echo "CircleCI: Remove read-only keys."
RO_KEYS=$(curl -v -sS --fail -u "${USERNAME}:${PASSWORD}" -X GET \
               -H "Accept: application/vnd.github.v3+json" \
               "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_NAME}/keys" \
          | jq -r '.[]| select(.read_only == true) | [.id]| @sh')

echo $RO_KEYS
for RO_KEY in ${RO_KEYS};
do
  curl -sS --fail -u "${USERNAME}:${PASSWORD}" -X DELETE "https://api.github.com/repos/${EXCHANGE_ORG}/${REPO_NAME}/keys/${RO_KEY}"
done

# Clean up
rm -rf "${REPO_DIR}" "/tmp/${PACK}_rsa*" "/tmp/${PACK}_user_token"
