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
flvcda='parse.php?kw=http://v.youku.com/v_show/id_'
# flvcdb='.html&format=high'
flvcdc='.html&format=super'
echo $sid

if [ ! -e $sid".html" ]
then
	echo "Analysing on the video provider web linkn"
	wget --output-document=$sid.html "http://flvcd.com/$flvcda$sid$flvcdc"
	# tt=$(cat "$sid.html" | grep "<title>.*<\/title>" | sed "s/.*<title>\(.*\)<\/title>.*/\1/")
	# if echo $tt | grep -q "301" 
	# then
	# 	echo "No super quality files for this video, try on the high quality instead"
	# 	curl -o $sid".html" "http://flvcd.com/$flvcda$sid$flvcdb"
	# fi
fi
cat $sid".html" | grep "document.title" | sed "s/.*document.title = \"\(.*\)\" + \".*/\1/"
# title=$(cat $sid".html" | grep "document.title" | sed "s/.*document.title = \"\(.*\)\" + \".*/\1/")
 
cat $sid".html" | grep 'http://f.youku.com/' > $sid.down
# | sed "s/.*<a.*href.*=.*\([0-9a-zA-Z/:.?,-]*\).*/\1/" > $sid.down
cat $sid.down


# if [ ! -e $sid".xml" ] ; then curl -o $sid".xml" "http://v.youku.com/player/getPlayList/VideoIDS/"$sid; fi
# tmpf=$(date +%s)
# let tmps=1000+$RANDOM*999/32767
# let tmpt=1000+$RANDOM*9000/32767
# ffield=$tmpf$tmps$tmpt

