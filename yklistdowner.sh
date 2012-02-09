#!/bin/bash
#===============================================================================
#
#          FILE:  yklistdowner.sh
# 
#         USAGE:  ./yklistdowner.sh url 
# 
#   DESCRIPTION:  To download all videos in youku playlist
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Lichi Zhang (), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  0.7
#       CREATED:  02/05/2012 01:52:26 AM GMT
#      REVISION:  ---
#===============================================================================

pid=$(echo $1 | sed "s/.*id_\([0-9a-zA-Z]*\).html/\1/")
mkdir $pid;cd $pid; # create a temp folder to download the videos
curl -o $pid.html $1
cat $pid".html" | grep "v_playlist\|\/v_show\/id" | sed "s/.*href=\"\(.*\).html.*/\1/" > temp.down
uniq temp.down > $pid.down
rm temp.down

num=$(wc -l < $pid".down")
for ((i=1;i<$num;i++))
do
	echo "Start No.$i video"
	url=$(awk "NR==$i" $pid".down").html
	../ykdowner.sh $url
done
