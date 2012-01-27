#!/bin/sh
echo "Analysing on the input web link"
curl --compressed -o index.html $1 
#curl $1 |gunzip > index.html
#curl -v to do debug; bilibili's webpages are compressed as gzip

