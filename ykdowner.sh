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
#       VERSION:  0.5 
#       CREATED:  02/03/2012 06:56:53 PM GMT
#      REVISION:  ---
#===============================================================================

sid=$(echo $1 | sed "s/.*id_\(.*\).html/\1/")
mkdir $sid;cd $sid #create a temp folder to download the video
curl -o temp.html $1
title=$(cat temp".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/" | sed "s/\?//")
rm temp.html
flvcda='parse.php?kw=http://v.youku.com/v_show/id_'
# flvcdb='.html&format=high'
flvcdc='.html&format=super'
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

cat $sid".html" | grep 'http://f.youku.com/' > temp.down
sed -e '/<U>/d' -e '/<br>/d' -e '/<BR>/d' -e 's/<input type="hidden" name="inf" value="//' temp.down > $sid.down
# rm temp.down 

num=$(wc -l < $sid".down")
format=$(sed -e "s/.*\/st\/\(.\{3\}\).*/\1/p" < $sid".down"| sed -n '1p')

# aria2c -U firefox -i $sid.down
# for ((i=1;i<=$num;i++))
# do
# 	if [ ! -e part$i.$format ] ; then url=$(sed -n "$i"p < $sid".down"); echo $url ; wget -U firefox --output-document=part$i.$format "$url"; fi 
# done
# 
# read start
# 
mencoder -forceidx -oac mp3lame -ovc copy -o "$sid- $title.$format" *.$format
mv "$sid - $title.$format" ../;cd ..;rm -rf $sid

# if [ ! -e $sid".xml" ] ; then curl -o $sid".xml" "http://v.youku.com/player/getPlayList/VideoIDS/"$sid; fi
# tmpf=$(date +%s)
# let tmps=1000+$RANDOM*999/32767
# let tmpt=1000+$RANDOM*9000/32767
# ffield=$tmpf$tmps$tmpt

