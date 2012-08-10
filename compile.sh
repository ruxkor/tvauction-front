#!/bin/bash 

while [ 1 ]; do
	RES_JADE=$(
		jade -P -O app src/*.jade >/dev/null;
		jade -P -O app/partials src/partials/*.jade >/dev/null;
	)
	RES_COFFEE=$(
		coffee -cb -o app/js src/coffee/*.coffee 2>&1
	)
	RES_LESS=$(
		lessc src/less/app.less > app/css/app.css
	)
	[ -n "$RES_JADE" ] && notify-send "jade error" && echo "$RES_JADE"
	[ -n "$RES_COFFEE" ] && notify-send "coffee error" && echo "$RES_COFFEE"
	echo $RES
	inotifywait -r -e modify -q src
	echo -e "----\n\n"
	done

