#!/bin/bash
#===============================================================================
#
#          FILE:  tddowner.sh
# 
#         USAGE:  ./tddowner.sh 
# 
#   DESCRIPTION:  To download video files from Tudou
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Lichi Zhang (), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  0.7 
#       CREATED:  02/03/2012 06:56:53 PM GMT
#      REVISION:  ---
#===============================================================================
sid=$(echo $1 | sed "s/.*view\/\([0-9a-zA-Z]*\).*/\1/")
mkdir $sid;cd $sid #create a temp folder to download the video
curl --compressed $1 > $sid".html" 
title=$(cat $sid".html"  | grep "<title>" | sed -e 's/</\n</g' -e 's/>/>\n</g' | sed -n '3p')
flvcda='http://v2.tudou.com/v?st=1%2C2%2C3%2C4%2C99&it='
tuid=$(grep -i "iid =" < $sid".html" | sed "s/\,iid = \([0-9]*\)$/\1/")
echo $sid

# if [ ! -e $sid".html" ]
# then
	echo "Analysing on the video provider web link"
	wget --output-document=$sid.xml "$flvcda$tuid"
	# tt=$(cat "$sid.html" | grep "<title>.*<\/title>" | sed "s/.*<title>\(.*\)<\/title>.*/\1/")
	# if echo $tt | grep -q "301" 
	# then
	# 	echo "No super quality files for this video, try on the high quality instead"
	# 	curl -o $sid".html" "http://flvcd.com/$flvcda$sid$flvcdb"
	# fi
# fi

cat $sid".xml" | grep -i 'http'  > temp.down
sed "s/.*brt=\".\">\(.*\)<.f>.*/\1/" temp.down > $sid".down"
url=$(cat $sid".down")
rm temp.down 

num=$(wc -l < $sid".down")
if grep -q f4v < $sid".down"
then
	format=f4v
elif grep -q mp4 < $sid".down"
then
	format=mp4
elif grep -q hlv < $sid".down"
then
	format=hlv
elif grep -q flv < $sid".down"
then
	format=flv
fi

wget --output-document="$sid - $title.$format" $url 

mv "$sid - $title.$format" ../;cd ..;rm -rf $sid
