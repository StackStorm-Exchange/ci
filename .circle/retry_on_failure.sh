#!/usr/bin/env bash

EXIT_CODE=0
MAX_RETRIES=5

COMMAND=$1

if [[ $# -ne 1 ]]; then
    echo "Usage: ${0} <shell command>"
    exit 1
fi

COUNT=0
while [[  ${COUNT} -lt ${MAX_RETRIES} ]]; do
   ${COMMAND}
   EXIT_CODE=$?

   if [[ ${EXIT_CODE} -eq 0 ]]; then
      exit 0
   fi

   echo "Command \"${COMMAND}\" failed with non-zero exit code, retrying..."
   SLEEP_DELAY=$((1 + RANDOM % 5))
   sleep ${SLEEP_DELAY}

   let COUNT=COUNT+1
done

echo "Command \"${COMMAND}\" failed after ${MAX_RETRIES} retries"
exit ${EXIT_CODE}
