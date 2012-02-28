#         USAGE:  ./bilidowner.sh url
# 
#   DESCRIPTION:  The shell script to download bilibili videos automatically, including the xml danmu files 
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  Finished...
#        AUTHOR:  Lichi Zhang (tigerdavid), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  1.0
#       CREATED:  01/28/2012 02:00:37 PM GMT
#      REVISION:  ---
#===============================================================================
# num=$(wc -l < av150607.list);for ((i=5;i<=$num;i++)); do ../bilidowner.sh http://www.bilibili.tv/video/av150607/index_$i.html; done
cookieloc=$(find ~/.mozilla/firefox/ -name "cookies.sqlite")
./extract_cookies.sh "$cookieloc" > /tmp/cookies.txt
id=$(echo $1 | sed "s/.*\(av[0-9]\{3,6\}\).*/\1/")
echo $id
mkdir $id;cd $id #create a temp folder to download the video
cp ../extract_cookies.sh ./ # so that bilidowner can catch this file
cp ../xml2ass.py ./
if [ ! -e $id".html" ]
then
	echo "Analysing on the input web link"
	curl --cookie /tmp/cookies.txt --compressed http://www.bilibili.tv/video/$id/index_1.html > $id".html" 
fi

cat $id".html" | grep -i "<.option>" | sed '/select/d' > $id.list
num=$(wc -l < $id".list")
for ((i=1;i<=$num;i++))
do
	../bilidowner.sh http://www.bilibili.tv/video/$id/index_$i.html
done
