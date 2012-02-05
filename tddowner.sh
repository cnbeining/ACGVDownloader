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
#       VERSION:  0.6 
#       CREATED:  02/05/2012 00:55:53 AM GMT
#      REVISION:  ---
#===============================================================================

sid=$(echo $1 | sed "s/.*\/v\/b\/\(.*\).html$/\1/")
mkdir $sid;cd $sid #create a temp folder to download the video
curl -o temp.html $1
title=$(cat temp".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/" | sed "s/\?//")
rm temp.html
flvcda='parse.php?kw=http://video.sina.com.cn/v/b/'
# flvcdb='.html&format=high'
flvcdc='.html'
echo $sid

# if [ ! -e $sid".html" ]
# then
	echo "Analysing on the video provider web link"
	wget --output-document=$sid.html "http://flvcd.com/$flvcda$sid$flvcdc"
	# tt=$(cat "$sid.html" | grep "<title>.*<\/title>" | sed "s/.*<title>\(.*\)<\/title>.*/\1/")
	# if echo $tt | grep -q "301" 
	# then
	# 	echo "No super quality files for this video, try on the high quality instead"
	# 	curl -o $sid".html" "http://flvcd.com/$flvcda$sid$flvcdb"
	# fi
# fi

cat $sid".html" | grep -i -e 'http://video.sinaedge.com' -e '58.63.235' > temp.down
sed -e '/<U>/d' -e '/<br>/d' -e '/<BR>/d' -e 's/<input type="hidden" name="inf" value="//' temp.down > $sid.down
rm temp.down 

num=$(wc -l < $sid".down")
format=hlv

for ((i=1;i<=$num;i++))
do
	let ii=i*2-1
	sed "$ii a\  out=part$i.$format" <$sid.down > temp.down
	mv temp.down $sid.down
done    

aria2c  -U firefox -i $sid.down

mencoder -forceidx -oac mp3lame -ovc copy -o "$sid - $title.$format" *.$format
mv "$sid - $title.$format" ../;cd ..;rm -rf $sid
