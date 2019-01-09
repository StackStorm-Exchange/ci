#!/usr/bin/env bash

# Script which copies over new sample circle config to all the pack repos
# NOTE: It assumes packs repos are cloned in a local directory where the script runs

for PACK_DIR in stackstorm-*; do
    echo "Processing pack: ${PACK_DIR}"
    PACK_DIR=`realpath ${PACK_DIR}`

    cd ${PACK_DIR}
    cp ~/ci/.circle/circle.yml.sample ${PACK_DIR}/.circleci/config.yml
    git add .circleci/config.yml
    git commit -m "Update CircleCI config from ci repo."
    git push origin master
    cd ..
done
