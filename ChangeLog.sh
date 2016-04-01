#!/bin/bash

# Script to read the ChangeLog from a Slackware mirror

# Copyright 2016  Chris Abela <kristofru@gmail.com>, Malta
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

URL=$( grep -v '#' /etc/slackpkg/mirrors )
PROTOCOL=$( echo "$URL" | cut -f1 -d: )
# Remove white spaces in $PROTOCOL
PROTOCOL=$( echo $PROTOCOL | sed 's/ //g')

# User chose more than one argument, this is not allowed
[ $# -gt 1 ] && \
  echo "Only one argument is allowed, exiting." && \
  exit 1

if [ $# == 1 ]; then
  # We have one argument, I will assume that the user wants it
  which "$1" > /dev/null 2>&1
  if [ $? == 0 ]; then
    $1 ${URL}ChangeLog.txt
  else echo "$1 not found"
  fi
  exit 2
fi

# User did not include any arguments, so we set up a menu to choose from 
# Let's start from the difficult ones Links v.s. LFTP:
case $PROTOCOL in
  http)
    # Links works only with http
    APPMENU=Links
    APP=links
    ;;
  ftp)
    # LFTP works only with FTP
    APPMENU=LFTP
    #APP="lftp -c more"
    APP=lftp
    ;;
  *) 
    echo Protocol not found
    exit 3
esac

# If Links/LFTP are not found we unset APPMENU and APP
which $APP > /dev/null 2>&1
[ $? == 0 ] || \
  unset APPMENU APP

# If found, Lynx should always work
which lynx > /dev/null 2>&1
[ $? == 0 ] && \
  APPMENU="$APPMENU Lynx"
  APP="$APP lynx"

# Check if user is using a desktop
xrandr > /dev/null 2>&1 && DESKTOP=Y
if [ "$DESKTOP" == Y ]; then
  # Seamonkey
  which seamonkey > /dev/null 2>&1  
  if [ $? == 0 ]; then
    APPMENU="$APPMENU Seamonkey"
    APP="$APP seamonkey"
  fi
  # Firefox
  which firefox > /dev/null 2>&1  
  if [ $? == 0 ]; then
    APPMENU="$APPMENU Firefox"
    APP="$APP firefox"
  fi
  # Konqueror 
  which konqueror > /dev/null 2>&1
  if [ $? == 0 ]; then
    APPMENU="$APPMENU Konqueror"
    APP="$APP konqueror"
  fi
  # Google Chrome
  which google-chrome-stable  > /dev/null 2>&1  
  if [ $? == 0 ]; then
    APPMENU="$APPMENU Chrome"
    APP="$APP google-chrome-stable"
  fi
fi

COUNTER=0
for i in $APPMENU; do
  let "COUNTER+=1"
  eval "APPMENU${COUNTER}"=$i
done

COUNTER=0
for i in $APP; do
  let "COUNTER+=1"
  eval "APP${COUNTER}"=$i
done

N=$( echo $APP | wc -w )
dialog --menu "Choose Your Web Browser:" 12 35 "$N" \
  1 "$APPMENU1" \
  2 "$APPMENU2" \
  3 "$APPMENU3" \
  4 "$APPMENU4" \
  5 "$APPMENU5" \
  6 "$APPMENU6" \
  2> /tmp/reply.ChangeLog

BROWSER=$( < /tmp/reply.ChangeLog )
rm /tmp/reply.ChangeLog

case $BROWSER in
  1)
     if [ $APPMENU1 = LFTP ]; then
       lftp -c more ${URL}ChangeLog.txt
     else $APP1 ${URL}ChangeLog.txt
     fi
     ;;
  2)
     $APP2 ${URL}ChangeLog.txt
     ;;
  3)
     $APP3 ${URL}ChangeLog.txt > /dev/null 2>&1
     ;;
  4)
     $APP4 ${URL}ChangeLog.txt > /dev/null 2>&1
     ;;
  5)
     $APP5 ${URL}ChangeLog.txt > /dev/null 2>&1
     ;;
  6)
     $APP6 ${URL}ChangeLog.txt > /dev/null 2>&1
     ;;
esac
