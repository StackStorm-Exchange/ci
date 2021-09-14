#!/bin/bash

# For python deps, please use requirements.txt or requirements-test.txt.
# Do not install python requirements with this script.

# Some packs need to install and configure additional packages to properly
# run their test suite. Other packs need to clone other repositories to
# reuse standardized testing infrastructure. And other functional or end-to-end
# tests might need additional system setup to access external APIs via
# an enterprise bus or something else.
# That is the purpose of this script. Setup the testing environment
# to do mock-less regression or end-to-end testing.

# This script is called by `deployment` housed in StackStorm-exchange/ci.
# `deployment` will only run this script if it is executable.
