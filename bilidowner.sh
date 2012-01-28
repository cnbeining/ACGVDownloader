#         USAGE:  ./bilidowner.sh url
# 
#   DESCRIPTION:  The shell script to download bilibili videos automatically, including the xml danmu files 
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  Not yet finished...
#        AUTHOR:  Lichi Zhang (tigerdavid), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  1.0
#       CREATED:  01/28/2012 02:00:37 PM GMT
#      REVISION:  ---
#===============================================================================

id=$(echo $1 | sed 's/.*\(av[0-9]\{6\}\).*/\1/')
echo $id
if [ ! -e $id".html" ]
then
	echo "Analysing on the input web link"
	curl --compressed -o $id".html" $1 
#curl $1 |gunzip > index.html
#curl -v to do debug; bilibili's webpages are compressed as gzip
fi

title=$(cat $id".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/")

v=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9]*\).*/\1/")
sid=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9]*\).*/\2/")

if [ $v=="vid" ]
then
	if [ ! -e $sid".xml" ] ; then curl -o $sid".xml" "v.iask.com/v_play.php?vid=$sid" ; fi
	cat $sid".xml"  | grep "<url>.*<.url>" | sed "s/.*\[CDATA\[\(.*\)\]\].*/\1/" > $sid".down"
	num=$(wc -l < $sid".down")
	format=$(sed "s/.*\([a-z]\{3\}\)$/\1/p" < $sid".down"| sed -n '1p')
	for ((i=1;i<=$num;i++))
	do
		(curl $(sed -n "$i"p < $sid".down") > "$title.part$i.$format" &) 
	done
	curl http://comment.bilibili.tv/dm,$sid > "$title.xml"	
fi

read start

touch "$title.$format"

for ((i=1;i<=$num;i++))
do
	mencoder -forceidx -of lavf -oac copy -ovc copy -o "$title.$format" "$title.$format" "$title.part$i.$format"	
done
