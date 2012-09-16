#!/bin/bash -e
BASEPATH="$(dirname $0)/.."

mysqldump --no-data --opt --skip-comments tvauction | sed 's$),($),\n($g' > $BASEPATH/data/schema.tvauction.sql
mysqldump --opt --skip-comments --no-create-info --complete-insert tvauction | sed 's$),($),\n($g' > $BASEPATH/data/data.tvauction.sql

