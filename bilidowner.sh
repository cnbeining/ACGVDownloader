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
ua="Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:10.0) Gecko/20100101 Firefox/10.0"
# read address from input and get $sid (original id from the source provider), $title and $v(which is used to know where did the video come from) 
cookieloc=$(find ~/.mozilla/firefox/ -name "cookies.sqlite")
./extract_cookies.sh "$cookieloc" > /tmp/cookies.txt
id=$(echo $1 | sed "s/.*\(av[0-9]\{5,6\}\).*/\1/")
echo $id
mkdir $id;cd $id #create a temp folder to download the video
if [ ! -e $id".html" ]
then
	echo "Analysing on the input web link"
	curl --cookie /tmp/cookies.txt --compressed $1 > $id".html" 
#curl $1 |gunzip > index.html
#curl -v to do debug; bilibili's webpages are compressed as gzip
fi

title=$(cat $id".html"  | grep "<title>.*<.title>" | sed "s/<title>\(.*\)<\/title>/\1/" | sed "s/^\(.*\).$/\1/")

v=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9a-zA-Z]*\).*/\1/")
sid=$(grep "play.swf" $id".html" | sed "s/.*flashvars=.\([a-z]*\)\=\([0-9a-zA-Z-]*\).*/\2/")

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
	curl --compressed http://www.tudou.com/programs/view/$sid > $sid".html"
	flvcda='http://v2.tudou.com/v?st=1%2C2%2C3%2C4%2C99&it='
	tuid=$(grep -i "iid =" < $sid".html" | sed "s/\,iid = \([0-9]*\)$/\1/")
	wget --output-document=$sid.xml "$flvcda$tuid"
	cat $sid".xml" | sed "s/>/>\n/g" | sed "s/</\n</g" | grep -i 'http' | sed -n '1p' > temp.down

else
	wget --output-document=$sid.html "http://flvcd.com/$flvcda$1"
	cat $sid".html" | grep -i "flv\|mp4\|f4v\|hlv" | grep -v 'flvcd\|FLVCD' > temp.down
fi

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
	let ii=i*10-9
# All these I made below are for that stupid tudou......
	sed "$ii a\  referer = http://www.google.com\n  load-cookies=/tmp/cookies.txt\n  out=part$i.$format\n  user-agent=$ua\n   header=Accept:text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\n   header=Accept-Language: en-us,en;q=0.5\n  header=Accept-Encoding: gzip,deflate\n   header=Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\n   header=Keep-Alive: 300" <$sid.down > temp.down
	mv temp.down $sid.down
done    

aria2c -c -i $sid.down
comm=''
for ((i=1;i<=$num;i++))
do
	comm="$comm part$i.$format"
done
echo $comm
if [ $format=="mp4" ]; then
	mencoder -mc 0 -ovc copy -oac mp3lame -lameopts cbr:br=128 -of lavf -lavfopts format=mp4 -o "$id - $title.$format" $comm
else
	mencoder -mc 0 -forceidx -oac mp3lame -lameopts cbr:br=128 -ovc copy -o "$id - $title.$format" $comm
fi
mv "$id - $title.$format" ../;cd ..;rm -rf $id

curl --cookie /tmp/cookies.txt --compressed -o "$id - $title.xml" "http://comment.bilibili.tv/dm,$sid"	

source ~/tigerdav/ENV/bin/activate # to start the virtualenv, comment this if you don't need to (or just ignore this...)
python xml2ass.py "$id - $title.xml"


