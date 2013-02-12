#!/bin/bash
#===============================================================================
#
#          FILE:  doudan.sh
# 
#         USAGE:  ./doudan.sh url
# 
#   DESCRIPTION:  Download doudan of tudou by reading url from one of video pages
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Lichi Zhang (), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  1.0
#       CREATED:  11/02/12 02:42:50 GMT
#      REVISION:  ---
#===============================================================================

pid=$(echo $1 | sed "s/.*playlist\/p\/\(.*\).html/\1/")
mkdir $pid;cd $pid; # create a temp folder to download the videos
curl --compressed -o $pid.html $1
cat $pid".html" | grep ',icode:' | sed "s/,icode:\"\(.*\)\"/http:\/\/www.tudou.com\/programs\/view\/\1\//"  > $pid".down"

num=$(wc -l < $pid".down")
for ((i=1;i<$num;i++))
do
	echo "Start No.$i video"
	url=$(awk "NR==$i" $pid".down")
	../tddowner.sh $url
done
