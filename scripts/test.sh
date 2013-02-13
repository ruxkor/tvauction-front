#!/bin/bash

BASE_DIR=`dirname $0`

echo ""
echo "Starting Testacular Server (http://vojtajina.github.com/testacular)"
echo "-------------------------------------------------------------------"

export CHROME_BIN=$(which chromium-browser)
testacular start $BASE_DIR/../config/testacular.conf.js $*
