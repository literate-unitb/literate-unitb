#!/bin/bash

# https://docs.haskellstack.org/en/stable/travis_ci/
# https://github.com/futurice/fum2github/blob/master/travis_long

$* &
pidA=$!
minutes=0

while true; do sleep 60; ((minutes++)); echo -e "\033[0;32m$minutes minute(s) elapsed.\033[0m"; done &
    pidB=$!

    wait $pidA
    exitCode=$?

    echo -e "\033[0;32m$* finished.\033[0m"

    kill -9 $pidB
    exit $exitCode
