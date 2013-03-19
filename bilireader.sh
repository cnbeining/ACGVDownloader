#         USAGE:  ./bilireader.sh source.html id
# 
#   DESCRIPTION:  The shell script to firstly read web page locations that have the videos inside from a local html file, and then download bilibili videos automatically from it, including the xml danmu files. You can have the html file by copying the rich texts with the link from the web page, then paste it to a rich text editor (I suggest to use this online editor http://www.html.am/), and save it in the html format.
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  Finished...
#        AUTHOR:  Lichi Zhang (tigerdavid), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  1.0
#       CREATED:  02/09/2012 02:00:37 PM GMT
#      REVISION:  ---
#===============================================================================
# num=$(wc -l < $id".list");for ((i=7;i<=$num;i++)); do url=$(sed -n "$i"'p' < richang.list);../bilidowner.sh $url;done

cookieloc=$(find ~/.mozilla/firefox/ -name "cookies.sqlite")
./extract_cookies.sh "$cookieloc" > /tmp/cookies.txt
id=$2
echo $id
mkdir $id;cd $id #create a temp folder to download the video
cp ../extract_cookies.sh ../xml2ass.py ../flv2mp4.sh ./ # so that bilidowner can catch this file
mv ../$1 ./

cat $1 | grep -i "<a href" | sed "s/.*<a href=\"\(.*\)\/\#titles.*/\1\//" > $id.list
num=$(wc -l < $id".list")
for ((i=1;i<=$num;i++))
do
	url=$(sed -n "$i"'p' < $id".list")
	../bilidowner.sh $url
done
