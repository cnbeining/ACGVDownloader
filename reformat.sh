cd $1
# find ./ -name '*.*' | grep -Ev '.xml|.ssa|.ass|.list|.down|.html|.sh|.swp|.aria2|.py' | sed '1d' > log
find ./ -name '*.mp4' > log
linenum=$(wc -l < log)

for ((i=1;i<=$linenum;i++))
do
	input=$(sed -n "$i"'p' < log)
	filename=$(echo $input | sed 's/\.[^\.]*$//')
#	extension=$(echo $input | sed 's/^.*\.//')
	mv "$input" temp.mp4
	ffmpeg -i temp.mp4 -threads 2 -acodec libfaac -ab 128k -vcodec libx264 -crf 21 -f mp4 "$filename.mp4"
	rm temp.mp4
done

rm log
