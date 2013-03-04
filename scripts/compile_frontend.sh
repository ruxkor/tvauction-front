#!/bin/bash 
BASE_DIR="$(dirname $(readlink -f $0))/.."
cd "$BASE_DIR"

while [ 1 ]; do
	RES_JADE=$(
		jade -P -O public public_src/*.jade >/dev/null;
		jade -P -O public/partials public_src/partials/*.jade >/dev/null;
	)
	RES_COFFEE=$(
		coffee -c -o public/js public_src/coffee/*.coffee 2>&1
		coffee -c -o test_frontend/unit test_frontend/unit/*.coffee 2>&1
		coffee -c -o test_frontend/e2e test_frontend/e2e/*.coffee 2>&1
	)
	RES_LESS=$(
		lessc public_src/less/app.less > public/css/app.css
	)
	[ -n "$RES_JADE" ] && notify-send "jade error" && echo "$RES_JADE"
	[ -n "$RES_COFFEE" ] && notify-send "coffee error" && echo "$RES_COFFEE"

	inotifywait -r -e modify -q public_src test test_frontend
done

