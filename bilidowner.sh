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

# read address from input and get $sid (original id from the source provider), $title and $v(which is used to know where did the video come from) 

id=$(echo $1 | sed "s/.*\(av[0-9]\{6\}\).*/\1/")
echo $id
if [ ! -e $id".html" ]
then
	echo "Analysing on the input web link"
	curl --compressed -o $id".html" $1 
#curl $1 |gunzip > index.html
#curl -v to do debug; bilibili's webpages are compressed as gzip
fi

title=$(cat $id".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/")

v=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9a-zA-Z]*\).*/\1/")
sid=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9a-zA-Z]*\).*/\2/")

# parse the real url and collect them into $sid.down file

case $v in
	"vid"
	echo "This video comes from Sina"
	if [ ! -e $sid".xml" ] ; then curl -o $sid".xml" "v.iask.com/v_play.php?vid=$sid" ; fi
	cat $sid".xml"  | grep "<url>.*<.url>" | sed "s/.*\[CDATA\[\(.*\)\]\].*/\1/" > $sid".down"
	;;
	"uid"
	echo "This video comes from Tudou"
	if [ ! -e $sid".html" ] ; then curl -o $sid".html" "http://www.tudou.com/programs/view/$sid"; fi	tuid=$(grep "iid =" $sid".html" | sed "s/.*\([0-9]\).*/\1/")
	if [ ! -e $sid".xml" ] ; then curl -o $sid".xml" "http://v2.tudou.com/v?st=1%2C2%2C3%2C4%2C99&it=$tuid"; fi
	cat $sid".xml" | sed "s/.*http\(.*\)<.f>/\1/" > $sid".down"
	;;
	"ykid"
	echo "This video comes from Youku"
	ykdowner.sh "http://v.youku.com/v_show/id_$sid.html"
	;;
	"qid"
	echo "This video comes from QQ"
	;;
	"rid"
	echo "This video comes from 6cn"
	;;
esac

# download the videos from $sid.down; I will put those lines below into an individual file so other downloader script can also use it

num=$(wc -l < $sid".down")
format=$(sed "s/.*\([a-z]\{3\}\)$/\1/p" < $sid".down"| sed -n '1p')
for ((i=1;i<=$num;i++))
do
        comm="$comm --index-out=$i=part$i.$format"
done    

aria2c $comm -U firefox -i $sid.down

curl -o "$title.xml" "http://comment.bilibili.tv/dm,$sid"	



