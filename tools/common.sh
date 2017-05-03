#!/usr/bin/env bash
# Common variables (environment variables) and functions used by the scripts

EXCHANGE_ORG="${EXCHANGE_ORG:-StackStorm-Exchange}"
EXCHANGE_PREFIX="${EXCHANGE_PREFIX:-stackstorm}"
SLEEP_DELAY="${SLEEP_DELAY:-2}"

function get_all_exchange_repo_names() {
  # Function which retrieves the names of all the pack repos and sets "REPO_NAME" variable with the result
  EXCHANGE_ORG=$1
  EXCHANGE_PREFIX=$2

  # 1. List all Github repos for the org
  REPO_NAMES=""
  API_URL="https://api.github.com/orgs/${EXCHANGE_ORG}/repos"
  # We have more than 100 repos. Max returned per page is 100. So need to figure out how many pages
  NUM_PAGES=$(curl -sI "${API_URL}?page=1&per_page=100" | sed -nr 's/^Link:.*page=([0-9]+)&per_page=100>; rel="last".*/\1/p')
  for (( i=1; i<=${NUM_PAGES}; i++ )); do
    REPO_NAMES="${REPO_NAMES} $(curl -sS --fail -X GET "${API_URL}?page=${i}&per_page=100" \
      | jq --raw-output ".[].name")"
  done

  OIFS=$IFS;
  IFS=" "
  REPO_NAMES=($REPO_NAMES)
  IFS=$OIFS;

  # 2. Filter out non pack repos
  REPO_NAMES=( $(for i in ${REPO_NAMES[@]} ; do echo $i ; done | grep "${EXCHANGE_PREFIX}-") )
}
