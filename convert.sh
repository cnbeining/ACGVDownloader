#!/bin/bash
#===============================================================================
#
#          FILE:  convert.sh
# 
#         USAGE:  ./convert.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Lichi Zhang (), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  1.0
#       CREATED:  02/09/2012 12:07:32 AM GMT
#      REVISION:  ---
#===============================================================================

ls *.xml > temp.list
num=$(wc -l < temp.list)
for ((i=1;i<=$num;i++))
do
	fn=$(sed -n "$i"'p' < temp.list);
	python xml2ass.py "$fn"
done
