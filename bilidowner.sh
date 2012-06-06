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
# Change this user agent information to what your browser has in below if you meet the 403 error while downloading
ua="Mozilla/5.0 (X11; Linux x86_64; rv:10.0.2) Gecko/20100101 Firefox/10.0.2"
# read address from input and get $sid (original id from the source provider), $title and $v(which is used to know where did the video come from) 
cookieloc=$(find ~/.mozilla/firefox/ -name "cookies.sqlite")
./extract_cookies.sh "$cookieloc" > /tmp/cookies.txt
id=$(echo $1 | sed "s/.*\(av[0-9]\{3,6\}\).*/\1/")
echo $id
mkdir $id;cd $id #create a temp folder to download the video
if [ ! -e $id".html" ]
then
	echo "Analysing on the input web link"
	curl --cookie /tmp/cookies.txt --compressed $1 > $id".html" 
	#curl $1 |gunzip > index.html
	#curl -v to do debug; bilibili's webpages are compressed as gzip
fi

title=$(cat $id".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/" | sed -e 's/^\(.*\).$/\1/' -e 's_/_ _g')
echo $title
v=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9a-zA-Z]*\).*/\1/")
sid=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9a-zA-Z_-]*\).*/\2/")
if [ -z $v ]
then
	string=$(grep 'secure' $id'.html' | sed "s_.*https://secure.bilibili.tv/secure,\(.*\)\" scrolling.*_\1_")
	v=$(echo $string | sed "s/^\([a-z]*\)=.*/\1/")
	sid=$(echo $string | sed "s/^\([a-z]*\)=\(.*\)$/\2/" | sed 's/=/\//')
fi
flvcda='parse.php?kw='
# flvcdb='.html&format=high'

echo "Analysing on the video provider web link"
if [ "$v" = "ykid" ]
then
	wget --output-document=$sid.html "http://flvcd.com/"$flvcda"http://v.youku.com/v_show/id_"$sid".html&format=super"
	cat $sid".html" | grep -i "flv\|mp4\|f4v\|hlv" | grep -v 'flvcd\|FLVCD' > temp.down
	if [ ! -s temp.down ]
	then
		wget --output-document=$sid.html "http://flvcd.com/"$flvcda"http://v.youku.com/v_playlist/"$sid".html&format=super"
		cat $sid".html" | grep -i "flv\|mp4\|f4v\|hlv" | grep -v 'flvcd\|FLVCD' > temp.down
	fi
elif [ "$v" = "uid" ]
then
	#	aria2c --out=$sid.html "http://flvcd.com/"$flvcda"http://www.tudou.com/programs/view/"$sid".html&format=real"
	#	cat $sid".html" | grep -i "flv\|mp4\|f4v\|hlv" | grep -v 'flvcd\|FLVCD' > temp.down
	curl --compressed http://www.tudou.com/programs/view/$sid > $sid".html"
	flvcda='http://v2.tudou.com/v?st=1%2C2%2C3%2C4%2C99&it='
	tuid=$(grep -i "iid =" < $sid".html" | sed "s/\,iid = \([0-9]*\)$/\1/")
	wget --output-document=$sid.xml "$flvcda$tuid"
	cat $sid".xml" | sed "s/>/>\n/g" | sed "s/</\n</g" | grep -i 'http' | sed -n '1p' > temp.down
elif [ "$v" = "vid" ]
then
	aria2c --out=$sid.xml 'http://v.iask.com/v_play.php?vid='$sid
	cat $sid".xml" | grep 'http' | sed "s/.*CDATA\[\(.*\)\]\].*/\1/" > temp.down
elif [ "$v" = "rid" ]
then
	rid=$sid
	sid='6cn'
	curl --compressed 'http://6.cn/v72.php?vid='$rid > $sid.xml
	roomid=$(cat "$sid.xml" | grep "<id>" | sed "s/<id>\(.*\)<\/id>/\1/")
	curl "'http://flvcd.com/'$flvcda'http://www.6cn/watch/'$roomid'.html&flag=&format='" > $sid.html
	cat $sid.html | sed "s_http://barcelona.6rooms.com_http://nantes.6rooms.com_g" > temp.down
	#cat "6cn.xml" | grep "<file>" | sed "s/<file>\(.*\)<\/file>/\1/" | sed "s_http://barcelona.6rooms.com_http://nantes.6rooms.com_" > $sid.down
elif [ "$v" = "qid" ]
then
	host="header=Host:v2.bilibili.tv"
	echo "http://videotfs.tc.qq.com:80/"$sid".flv?channel=vhot2&sdtfrom=v2&r=60&rfc=v0" > $sid.down
else
	wget --output-document=$sid.html "http://flvcd.com/$flvcda$1"
	cat $sid".html" | grep -i "flv\|mp4\|f4v\|hlv" | grep -v 'flvcd\|FLVCD' > temp.down
fi

if [ ! -e $sid.down ]
then
	cat temp.down | sed  -e '/<br>/d' -e '/<BR>/d' -e '/<script/d' -e "/\r/d" -e 's/<U>//' | sed '/</d' > temp2.down
	uniq temp2.down | sed 's/amp;//g' > $sid".down"
	rm temp.down temp2.down
fi

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
	let ii=i*10-9
	# All these I made below are for that stupid tudou and qq......
	sed "$ii a\ $host\n  load-cookies=/tmp/cookies.txt\n  out=part$i.$format\n  user-agent=$ua\n   header=Accept:text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n   header=Accept-Language:en-gb,en;q=0.5\n  header=Accept-Encoding: gzip,deflate\n   header=Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\n   header=Connection:keep-alive" <$sid.down > temp.down
	mv temp.down $sid.down
done    

aria2c -x10 -c -i $sid.down
if [ "$format" != 'mp4' ]
then
	#ffmpeg -i part1.$format -vcodec copy -acodec copy part1.mp4
	../flv2mp4.sh part1.$format part1.mp4
fi
comm='-add part1.mp4'
for ((i=2;i<=$num;i++))
do
	if [ "$format" != 'mp4' ]
	then
		#ffmpeg -i part$i.$format -vcodec copy -acodec copy part$i.mp4
		../flv2mp4.sh part$i.$format part$i.mp4
	fi
	comm="$comm -cat part$i.mp4"
done
echo $comm
MP4Box -force-cat $comm result.mp4
mv result.mp4 "$id - $title.mp4"

mv "$id - $title.mp4" ../;cd ..;
rm -rf $id

if [ "$rid" ]; then sid=$(echo $rid | sed '_/_=_');fi

curl --cookie /tmp/cookies.txt --compressed -o "$id - $title.xml" "http://comment.bilibili.tv/dm,$sid"	

source /usr/tigerdav/tigerdav/ENV/bin/activate # start the virtualenv, comment this if you don't need to (or just ignore this...)
python xml2ass.py "$id - $title.xml" 


