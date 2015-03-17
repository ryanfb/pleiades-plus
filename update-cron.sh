#!/bin/bash

# needed for ssh-agent auth under cron on OS X
declare -x SSH_AUTH_SOCK=$( find /tmp/com.apple.launchd.*/Listeners -user $(whoami) -type s | head -1 )

rm -fv *.csv.gz *.csv
rm -rfv /tmp/geonames
git checkout master
git pull
./create_pleiades_plus
git add data/pleiades-plus.csv
git commit -m "$(date '+%Y-%m-%d') pleiades-plus.csv update"
git checkout capgrids
git pull
git merge -s recursive -Xtheirs --no-edit master
./create_pleiades_plus
git add data/pleiades-plus.csv
git commit -m "$(date '+%Y-%m-%d') pleiades-plus.csv capgrids update"
git push
git checkout master
