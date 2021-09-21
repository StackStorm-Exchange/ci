#!/bin/bash

# Script which resets Github user token for a pack (repo) and submits new token info to
# Circle CI
#
# Requires: jq
#
# The following env variables must be specified:
# * GITHUB_USERNAME: a GitHub user to run the script under (Exchange bot).
# * CIRCLECI_TOKEN: a CircleCI token for the Exchange organization.
#
# HISTORICAL NOTE: GitHub disabled basic auth *with account passwords*[1]. Before that change,
# this script automatically generated the Personal Access Tokens (PATs) via an API call with
# account-password based basic auth. GitHub probably intends to force a "human in the loop" for
# PAT generation. As such, this script was modified to open a private/incognito browser window
# with the token details pre-filled. This is now the expected process for using this script:
#
#  1. Open https://github.com/settings/tokens/new in a new private/incognito browser window.
#  2. Log in with stackstorm-neptr, the StackStorm-Exchange's bot account (not a personal account).
#  3. Run this script:
#         GITHUB_USERNAME=stackstorm-neptr CIRCLECI_TOKEN=... \
#         ./tools/reset_github_user_token_and_update_circleci.sh pack1 pack2 pack3 pack4
#  4. The script prints instructions and opens the token generation page in the default browser
#  5. Manually scroll down and hit "Generate Token" (PAT name and scope are already filled in).
#  6. Copy PAT contents/value and paste in the terminal window (it is read as a secure password).
#  7. Wait for the script to load the PAT into the MACHINE_PASSWORD var in CircleCI
#     (The CircleCI APIs can be quite slow, so doing many packs takes awhile).
#  8. The script loops through steps 4-8 until all packs have been processed.
#
# [1] https://developer.github.com/changes/2020-02-14-deprecating-password-auth/

# WARNING: CircleCI's API is sloooooow, so minimize the number of calls we make to it
SET_MACHINE_USER=${SET_MACHINE_USER:-false}
for ARG in $@; do
    case $ARG in
    --set-user)
        SET_MACHINE_USER=true
        shift
        ;;
    *)
        break
        ;;
    esac
done

if [[ ! $# -gt 0 ]];
then
    echo "Usage: $0 [--set-user] <pack> [<pack> <pack> ...]"
    echo
    echo "By default, only sets MACHINE_PASSWORD to minimize CircleCI API calls."
    echo "Use --set-user if you need to also configure MACHINE_USER in CircleCI."
    echo "eg. Use --set-user when adding a new pack or fixing a misconfigured pack."
    exit 1
fi

OS=$(uname)
if [[ "${OS}" == "Darwin" ]]; then
    # We're on macOS
    # Figure out the default browser
    DEFAULT_BROWSER=$(plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist | grep 'https' -b3 |awk 'NR==3 {split($4, arr, "\""); print arr[2]}')
    if [[ "${DEFAULT_BROWSER}" == "org.mozilla.firefox" ]]; then
        BROWSER_NAME=Firefox
        BROWSER_COMMAND="/Applications/Firefox.app/Contents/MacOS/firefox -private-window"
    elif [[ "${DEFAULT_BROWSER}" == "com.google.chrome" ]]; then
        BROWSER_NAME=Chrome
        BROWSER_COMMAND='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --incognito'
    elif [[ "${DEFAULT_BROWSER}" == "com.apple.safari" ]]; then
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
    else
        echo "Unsupported default browser: ${DEFAULT_BROWSER}"
        echo "Supported: Firefox, Chrome, Safari"
        echo "PR welcome to add support for your Browser."
        exit 1
    fi
elif [[ "${OS}" == "Linux" ]]; then
    # We're on linux
    # Gnome, KDE, and other desktops each have different commands to run *.desktop files.
    # So, we roll our own runner (based on: https://askubuntu.com/a/664272 )
    DEFAULT_BROWSER=$(xdg-settings get default-web-browser)
    DEFAULT_BROWSER_DESKTOP=$(ls -1 {~/.local,/usr}/share/applications/${DEFAULT_BROWSER} 2>/dev/null | head -n1)
    DEFAULT_BROWSER_BIN=$(awk '/^Exec=/ {sub("^Exec=", ""); gsub(" ?%[cDdFfikmNnUuv]", ""); gsub(" -.*", ""); print($0); exit}' ${DEFAULT_BROWSER_DESKTOP})
    if [[ "${DEFAULT_BROWSER}" == *"firefox"* ]]; then
        BROWSER_NAME=Firefox
        BROWSER_COMMAND="${DEFAULT_BROWSER_BIN} -private-window"
    elif [[ "${DEFAULT_BROWSER}" == *"chrom"* ]] || [[ "${DEFAULT_BROWSER}" == *"brave"* ]]; then  # chrome or chromium
        BROWSER_NAME=Chrome
        BROWSER_COMMAND="${DEFAULT_BROWSER_BIN} --incognito"
    else
        echo "Unsupported default browser: ${DEFAULT_BROWSER_BIN}"
        echo "Supported: Firefox, Chrome, Chromium"
        echo "PR welcome to add support for your browser."
        exit 1
    fi
else
    echo "Unsupported OS: ${OS}. Can't detect browser."
    exit 1
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
if [[ -z "$GITHUB_USERNAME" ]];
then
    echo "What is the username for the GitHub user?"
    echo "Default: $DEFAULT_USERNAME (just hit enter to use this)"
    read GITHUB_USERNAME
    GITHUB_USERNAME="${GITHUB_USERNAME:-$DEFAULT_USERNAME}"
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
        # Space things out a bit with \n\n
        # And use printf instead of echo since so it add another newline
        printf "\n\n[${PACK_NUM}/${NUM_PACKS}]"
    fi
    echo " ${REPO_NAME}"
    echo

    echo "Please do the following when ${BROWSER_NAME} opens:"
    echo "  Select 'No expiration' under Expiration,"  # sadly we can't prefill this via url
    echo "  then click 'Generate Token' at the bottom,"
    echo "  and copy the GitHub PAT token for ${REPO_NAME} and paste it here:"
    eval "${BROWSER_COMMAND} 'https://github.com/settings/tokens/new?scopes=public_repo&description=CircleCI%3A%20${REPO_NAME}'"
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
    # use --set-user to enable setting this.
    if [[ ${SET_MACHINE_USER} == "true" ]]; then
        curl -sS --fail -X POST --header "Content-Type: application/json" \
            -d '{"name":"MACHINE_USER", "value":"'"${GITHUB_USERNAME}"'"}' \
            "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"
    fi
    curl -sS --fail -X POST --header "Content-Type: application/json" \
        -d '{"name":"MACHINE_PASSWORD", "value": "'"${GITHUB_USER_TOKEN}"'"}' \
        "https://circleci.com/api/v1.1/project/github/${EXCHANGE_ORG}/${REPO_NAME}/envvar?circle-token=${CIRCLECI_TOKEN}"

    # curl prints the response data, but doesn't print a newline
    echo
done
