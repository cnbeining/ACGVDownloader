#!/bin/bash
#===============================================================================
#
#          FILE:  extract_cookies.sh
# 
#         USAGE:  ./extract_cookies.sh 
# 
#   DESCRIPTION:  To extract cookies from firefox and convert it to txt file
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  Referred from this webpage: http://slacy.com/blog/2010/02/using-cookies-sqlite-in-wget-or-curl/
#        AUTHOR:  Lichi Zhang (), tigerdavidxeon@gmail.com
#       COMPANY:  University of York, UK
#       VERSION:  1.0
#       CREATED:  02/08/2012 03:03:29 AM GMT
#      REVISION:  ---
#===============================================================================

function cleanup {
rm -f $TMPFILE
exit 1
}

trap cleanup  SIGHUP SIGINT SIGTERM

# This is the format of the sqlite database:
# CREATE TABLE moz_cookies (id INTEGER PRIMARY KEY, name TEXT, value TEXT, host TEXT, path TEXT,expiry INTEGER, lastAccessed INTEGER, isSecure INTEGER, isHttpOnly INTEGER);

# We have to copy cookies.sqlite, because FireFox has a lock on it
TMPFILE=`mktemp /tmp/cookies.sqlite.XXXXXXXXXX`
cat $1 >> $TMPFILE
sqlite3 -separator '	' $TMPFILE << EOF
.mode tabs
.header off
select host,
case substr(host,1,1)='.' when 0 then 'FALSE' else 'TRUE' end,
path,
case isSecure when 0 then 'FALSE' else 'TRUE' end,
expiry,
name,
value
from moz_cookies;
EOF
cleanup
