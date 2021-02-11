#!/bin/bash

# Script which resets Github user token for a pack (repo) and submits new token info to
# Circle CI
#
# Requires: jq
#
# The following env variables must be specified:
# * USERNAME: a GitHub user to run the script under (Exchange bot).
# * CIRCLECI_TOKEN: a CircleCI token for the Exchange organization.
#

if [[ ! $# -gt 0 ]];
then
    echo "Usage: $0 <pack> [<pack> <pack> ...]"
    exit 1
fi

if [[ "$(uname)" == "Darwin" ]]; then
    # We're on macOS
    # Figure out the default browser
    DEFAULT_BROWSER=$(plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist | grep 'https' -b3 |awk 'NR==3 {split($4, arr, "\""); print arr[2]}')
    if [[ "$DEFAULT_BROWSER" == "org.mozilla.firefox" ]]; then
        BROWSER_NAME=Firefox
        BROWSER_COMMAND="/Applications/Firefox.app/Contents/MacOS/firefox -private-window"
    elif [[ "$DEFAULT_BROWSER" == "com.google.chrome" ]]; then
        BROWSER_NAME=Chrome
        BROWSER_COMMAND='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --incognito'
    elif [[ "$DEFAULT_BROWSER" == "com.apple.safari" ]]; then
        BROWSER_NAME=Safari
        open_in_safari() {
            echo "
tell application \"Safari\"
    activate
    delay 0.5
    tell window 1
        set current tab to (make new tab with properties {URL: \"$1\"})
    end tell
end tell" | osascript
        }
        BROWSER_COMMAND=open_in_safari
    fi
fi

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

NUM_PACKS=$#

PACK_NUM=0
for PACK in $@; do
    PACK_NUM=$(($PACK_NUM+1))
    REPO_NAME=$(repo_name ${PACK})

    # If we're doing more than one pack, add some whitespace and a counter
    if [[ $NUM_PACKS -gt 1 ]]; then
        # Space things out a bit
        echo
        echo

        # Use printf instead of echo since it doesn't include a newline terminator
        printf "[${PACK_NUM}/${NUM_PACKS}]"
    fi
    echo " ${REPO_NAME}"
    echo

    echo "Please click 'Generate Token' when ${BROWSER_NAME} opens."
    echo "Then copy the GitHub PAT token for ${REPO_NAME} and paste it here:"
    eval "${BROWSER_COMMAND} https://github.com/settings/tokens/new?scopes=public_repo&description=CircleCI%3A%20${REPO_NAME}"
    read -s GITHUB_USER_TOKEN

    # If you click the copy button in GitHub's UI it will copy correctly.
    # But if you double click to highlight it, and then copy it manually it
    # include a leading space character.
    # Instead of giving users a loaded footgun, strip whitespace off the ends
    # of the PAT.
    # See https://stackoverflow.com/a/12973694
    GITHUB_USER_TOKEN=$(echo $GITHUB_USER_TOKEN | xargs)
    if [[ -z "$GITHUB_USER_TOKEN" ]];
    then
        echo "Could not create a GitHub Personal Access Token."
        exit 1
    fi

    echo

    # CircleCI: specify the credentials (the machine login and the new user-scope token)
    echo "CircleCI: Setting credentials (machine login and user-scoped token)"
    # CircleCI's API is sloooooow, so minimize the number of calls we make to it
    # TODO: Hide this behind a command line flag
    # curl -sS --fail -X POST --header "Content-Type: application/json" \
    #     -d '{"name":"MACHINE_USER", "value":"'"${USERNAME}"'"}' \
    #     "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"
    curl -sS --fail -X POST --header "Content-Type: application/json" \
        -d '{"name":"MACHINE_PASSWORD", "value": "'"${GITHUB_USER_TOKEN}"'"}' \
        "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"

    # curl prints the response data, but doesn't print a newline
    echo
done
