#!/bin/bash
#===============================================================================
#
#          FILE:  qqdowner.sh
# 
#         USAGE:  ./qqdowner.sh url
# 
#   DESCRIPTION:  To download video files from Tecent
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

sid=$(echo $1 | sed "s/.*cover\/.\/\(.*\).html$/\1/")
mkdir $sid;cd $sid #create a temp folder to download the video
curl $1 > temp".html" 
title=$(cat temp".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/" | sed "s/^\(.*\).$/\1/")
rm temp.html
flvcda='parse.php?kw='
echo $sid

# if [ ! -e $sid".html" ]
# then
	echo "Analysing on the video provider web link"
	wget --output-document=$sid.html "http://flvcd.com/$flvcda$1"
	# tt=$(cat "$sid.html" | grep "<title>.*<\/title>" | sed "s/.*<title>\(.*\)<\/title>.*/\1/")
	# if echo $tt | grep -q "301" 
	# then
	# 	echo "No super quality files for this video, try on the high quality instead"
	# 	curl -o $sid".html" "http://flvcd.com/$flvcda$sid$flvcdb"
	# fi
# fi

cat $sid".html" | grep -i "222.73.3" > temp.down
cat temp.down | sed  -e '/<br>/d' -e '/<BR>/d' -e '/<script/d' -e "/\r/d" -e 's/<U>//' | sed '/</d' > temp2.down
uniq temp2.down | sed 's/amp;//g' > $sid".down"
rm temp.down temp2.down

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

for ((i=1;i<=$num;i++))
do
	let ii=i*2-1
	sed "$ii a\  out=part$i.$format" <$sid.down > temp.down
	mv temp.down $sid.down
done    

aria2c  -U firefox -i $sid.down

comm=''
for ((i=1;i<=$num;i++))
do
	comm="$comm part$i.$format"
done
echo $comm
if [ $format=="mp4" ]; then
	mencoder -ovc copy -oac mp3lame -of lavf -lavfopts format=mp4 -o "$sid - $title.$format" $comm
else
	mencoder -forceidx -oac mp3lame -ovc copy -o "$sid - $title.$format" $comm
fi
mv "$sid - $title.$format" ../;cd ..;rm -rf $sid
