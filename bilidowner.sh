#!/bin/sh
id=$(echo $1 | sed 's/.*\(av[0-9]\{6\}\).*/\1/')
echo $id
if [ ! -e $id".html" ]
then
	echo "Analysing on the input web link"
	curl --compressed -o $id".html" $1 
#curl $1 |gunzip > index.html
#curl -v to do debug; bilibili's webpages are compressed as gzip
fi

title=$(cat $id".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/")
echo $title

v=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9]*\).*/\1/")
sid=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9]*\).*/\2/")
echo $v$sid

if [ $v=="vid" ]
then
	if [ ! -e $sid".xml" ] ; then curl -o $sid".xml" "v.iask.com/v_play.php?vid=$sid" ; fi
	num=$(cat $sid".xml"  | grep "<order>.*<.order>" | sed "s/<order>\([0-9]*\)<\/order>/\1/")
	url=$(cat $sid".xml"  | grep "<url>.*<.url>" | sed "s/.*\[CDATA\[\(.*\)\]\].*/\1/")
	format=$(echo $url | sed "s/.*\([a-z]\{3\}\)$/\1/")
	echo $num $url $format
#	curl $url > $title"."$format
#	curl http://comment.bilibili.tv/dm,$sid > $title".xml"	
fi 
