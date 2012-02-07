#!/bin/bash
#===============================================================================
#
#          FILE:  ykdowner.sh
# 
#         USAGE:  ./ykdowner.sh url
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

if grep -q v_playlist <<<$1
then
	sid=$(echo $1 | sed "s/.*v_playlist\/\(.*\).html/\1/");
elif grep -q id_ <<<$1
then
	sid=$(echo $1 | sed "s/.*id_\(.*\).html/\1/")
fi

# sid=$(echo $1 | sed "s/.*id_\(.*\).html/\1/")
# if [ $sid==$1 ] ; then sid=$(echo $1 | sed "s/.*v_playlist\/\(.*\).html/\1/"); fi
mkdir $sid;cd $sid #create a temp folder to download the video
curl $1  > temp".html"
title=$(cat temp".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/" | sed "s/^\(.*\).$/\1/")
rm temp.html
flvcda='parse.php?kw='
# flvcdb='.html&format=high'
flvcdc='&format=super'
echo $sid

# if [ ! -e $sid".html" ]
# then
	echo "Analysing on the video provider web link"
	wget --output-document=$sid.html "http://flvcd.com/$flvcda$1$flvcdc"
	# tt=$(cat "$sid.html" | grep "<title>.*<\/title>" | sed "s/.*<title>\(.*\)<\/title>.*/\1/")
	# if echo $tt | grep -q "301" 
	# then
	# 	echo "No super quality files for this video, try on the high quality instead"
	# 	curl -o $sid".html" "http://flvcd.com/$flvcda$sid$flvcdb"
	# fi
# fi

cat $sid".html" | grep 'http://f.youku.com/' > temp.down
sed -e '/<U>/d' -e '/<br>/d' -e '/<BR>/d' -e 's/<input type="hidden" name="inf" value="//' temp.down > $sid.down
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

for ((i=1;i<=$num;i++))
do
	let ii=i*2-1
	sed "$ii a\  out=part$i.$format" <$sid.down > temp.down
	mv temp.down $sid.down
done    

aria2c -U firefox -i $sid.down

if [ $format=="mp4" ]; then
	mencoder -ovc copy -oac mp3lame -of lavf -lavfopts format=mp4 -o "$sid - $title.$format" *.$format
else
	mencoder -forceidx -oac mp3lame -ovc copy -o "$sid - $title.$format" *.$format
fi
mv "$sid - $title.$format" ../;cd ..;rm -rf $sid

# if [ ! -e $sid".xml" ] ; then curl -o $sid".xml" "http://v.youku.com/player/getPlayList/VideoIDS/"$sid; fi
# tmpf=$(date +%s)
# let tmps=1000+$RANDOM*999/32767
# let tmpt=1000+$RANDOM*9000/32767
# ffield=$tmpf$tmps$tmpt

