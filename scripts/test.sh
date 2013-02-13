#!/bin/bash

BASE_DIR=`dirname $0`

java -jar "$BASE_DIR/../test_frontend/lib/jstestdriver/JsTestDriver.jar" \
     --config "$BASE_DIR/../config/jsTestDriver.conf" \
     --basePath "$BASE_DIR/.." \
     --tests all \
     --captureConsole
