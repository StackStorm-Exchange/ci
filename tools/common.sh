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
  REPO_NAMES=$(curl -sS --fail -X GET "https://api.github.com/orgs/${EXCHANGE_ORG}/repos?per_page=1000" \
      | jq --raw-output ".[].name")

  OIFS=$IFS;
  IFS=" "
  REPO_NAMES=($REPO_NAMES)
  IFS=$OIFS;

  # 2. Filter out non pack repos
  REPO_NAMES=( $(for i in ${REPO_NAMES[@]} ; do echo $i ; done | grep "${EXCHANGE_PREFIX}-") )
}
