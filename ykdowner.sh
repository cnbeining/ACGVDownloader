#!/bin/bash
#===============================================================================
#
#          FILE:  ykdowner.sh
# 
#         USAGE:  ./ykdowner.sh 
# 
#   DESCRIPTION:  To download video files from Youku
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Lichi Zhang (), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  1.0
#       CREATED:  02/03/2012 06:56:53 PM GMT
#      REVISION:  ---
#===============================================================================

sid=$(echo $1 | sed "s/.*id_\(.*\).html/\1/")
echo $sid

if [ ! -e $sid".html" ]
then
	echo "Analysing on the input web link"
	curl -o $sid".html" $1
fi

title=$(cat $sid".html" | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1")
 
if [ ! -e $sid".xml" ] ; then curl -o $sid".xml" "http://v.youku.com/player/getPlayList/VideoIDS/"$sid; fi
tmpf=$(date +%s)
let tmps=1000+$RANDOM*999/32767
let tmpt=1000+$RANDOM*9000/32767
ffield=$tmpf$tmps$tmpt

