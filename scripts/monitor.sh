#!/bin/bash -e
BASE_DIR="$(dirname $(readlink -f $0))/.."
cd "$BASE_DIR"

PID=0
while true; do
	[ $PID -ne 0 ] && kill $PID
	DEBUG=tvauction:* _coffee --fibers index._coffee &
	PID=$!
	inotifywait -q -e modify index._coffee app/*._coffee
done
