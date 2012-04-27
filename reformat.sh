cd /media/misc/online/
find ./ -name '*.*' | grep -Ev '.xml|.ssa|.ass|.list|.down|.html|.sh|.swp|.aria2|.py' | sed '1d' > log
linenum=$(wc -l < log)

for ((i=1;i<=$linenum;i++))
do
	input=$(sed -n "$i"'p' < log)
	filename=$(echo $input | sed 's/\.[^\.]*$//')
#	extension=$(echo $input | sed 's/^.*\.//')
	ffmpeg -i "$input" -threads 0 -acodec libfaac -ab 128k -vcodec copy -ar 48000 -f mp4 "$filename.mp4"
	rm "$input"
done
