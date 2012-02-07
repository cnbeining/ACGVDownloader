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

sid=$(echo $1 | sed "s/.*view\/\(.*\)$/\1/")
mkdir $sid;cd $sid #create a temp folder to download the video
curl $1 > temp".html" 
title=$(cat temp".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/" | sed "s/^\(.*\).$/\1/")
rm temp.html
flvcda='parse.php?kw='
# flvcdb='.html&format=high'
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

cat $sid".html" | grep -i '180.153.94'  > temp.down
sed -e '/<U>/d' -e '/<br>/d' -e '/<BR>/d' -e 's/<input type="hidden" name="inf" value="//' temp.down > $sid.down
rm temp.down 

num=$(wc -l < $sid".down")
format=$(cat $sid".down" | sed "s/.*[0-9.]*\/\(.\{3\}\).*/\1/" | sed -n '1p')

for ((i=1;i<=$num;i++))
do
	let ii=i*2-1
	sed "$ii a\  out=part$i.$format" <$sid.down > temp.down
	mv temp.down $sid.down
done    

aria2c  -U firefox -i $sid.down

if [ $format=="mp4" ]; then
	mencoder -ovc copy -oac mp3lame -of lavf -lavfopts format=mp4 -o "$sid - $title.$format" *.$format
else
	mencoder -forceidx -oac mp3lame -ovc copy -o "$sid - $title.$format" *.$format
fi

mv "$sid - $title.$format" ../;cd ..;rm -rf $sid
