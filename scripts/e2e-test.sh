#!/bin/bash -e

BASE_DIR=$(dirname $(readlink -f $0))
export CHROME_BIN=$(which chromium-browser)
ARGS="$*"

cd $BASE_DIR

echo "Initializing Database"
SQL_INIT="DROP DATABASE tvauction_test; CREATE DATABASE tvauction_test;"
mysql -v -e "$SQL_INIT"

echo "Starting Server"
_coffee --fibers index._coffee -d "$TEST_DB" &>/dev/null &
SERVER_PID=$!

echo "Starting Testacular Server"
# testacular start ./config/testacular-e2e.conf.js $ARGS

echo "Killing Server (PID $SERVER_PID)"
kill $SERVER_PID