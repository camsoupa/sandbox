#!/bin/bash

filename=$1
curl --data-urlencode "file@${filename}" -d "lex=1" http://matt.might.net/apps/pyparse/pyparse.php > "${filename}.parsed"

