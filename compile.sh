#!/bin/bash 

while [ 1 ]; do
	RES_JADE=$(
		jade -P -O public public_src/*.jade >/dev/null;
		jade -P -O public/partials public_src/partials/*.jade >/dev/null;
	)
	RES_COFFEE=$(
		coffee -cb -o public/js public_src/coffee/*.coffee 2>&1
	)
	RES_LESS=$(
		lessc public_src/less/app.less > public/css/app.css
	)
	[ -n "$RES_JADE" ] && notify-send "jade error" && echo "$RES_JADE"
	[ -n "$RES_COFFEE" ] && notify-send "coffee error" && echo "$RES_COFFEE"
	echo $RES
	inotifywait -r -e modify -q public_src
	echo -e "----\n\n"
	done

