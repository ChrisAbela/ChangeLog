#!/bin/bash

# A sophisticated script to read the ChangeLog from a Slackware mirror

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

function add_app() {
  eval which "$2" > /dev/null 2>&1 && \
  APPMENU="$APPMENU $1"
  APP="$APP $2"
}

function Native() {
  cd /tmp/
  rm -f ChangeLog.txt
  wget -q ${URL}ChangeLog.txt
  dialog --title "ChangeLog.txt" \
    --textbox ChangeLog.txt 35 80
  rm -f ChangeLog.txt
}

URL=$( grep -v '#' /etc/slackpkg/mirrors )
if [ $( echo $URL | wc -w ) -ne 1 ]; then
  echo "/etc/slackpkg/mirrors is not set"
  exit
fi

PROTOCOL=$( echo "$URL" | cut -f1 -d: )
# Remove white spaces in $PROTOCOL
PROTOCOL=$( echo $PROTOCOL | sed 's/ //g')

# User chose more than one argument, this is not allowed
[ $# -gt 1 ] && \
  echo "Only one argument is allowed, exiting." && \
  exit

if [ $# -eq 1 ]; then
  # We have one argument, we will assume that the user wants it
  if eval which "$1" > /dev/null 2>&1 ; then
    case $1 in
      lftp)
	[ $PROTOCOL == http ] && \
	  echo LFTP cannot read http && \
	  exit
        lftp -c more ${URL}ChangeLog.txt
        ;;
      *)
        [ $PROTOCOL == ftp ] && [ $1 == links ] && \
	   echo Links cannot read ftp && \
	   exit
        $1 ${URL}ChangeLog.txt
      esac
  elif [ "$1" == native ]; then
    Native
  else echo "$1 not found"
  exit
  fi
  exit
fi

# User did not include any arguments, so we set up a menu to choose from

# Let's start from the native browser
APPMENU=Native
APP=wget

# Then the difficult ones: Links v.s. LFTP:
case $PROTOCOL in
  http)
    # Links works only with http
    which links > /dev/null 2>&1 && \
      APPMENU="$APPMENU Links"
      APP="$APP links"
    ;;
  ftp)
    # LFTP works only with FTP
    which lftp > /dev/null 2>&1 && \
      APPMENU="$APPMENU LFTP"
      APP="$APP lftp"
    ;;
  *) 
    echo "Protocol $PROTOCOL is not supported" 
    exit
esac

# If found, Lynx should always work
which lynx > /dev/null 2>&1 && \
  APPMENU="$APPMENU Lynx"
  APP="$APP lynx"

# Check if user is using a desktop
if eval xrandr > /dev/null 2>&1 ; then
  # Feel free to edit this list
  # This should pass two arguments to function add_app
  # The first argument is the menu entry
  # The second argument is the application itself
  add_app Seamonkey seamonkey
  add_app Firefox firefox
  add_app Konqueror konqueror
  add_app Chrome google-chrome-stable
fi

N=$( echo $APP | wc -w )
[ $N -eq 0 ] && \
  echo No Browser Found, exiting && \
  exit
DLENGTH=$(( $N * 2 + 4 ))

COUNTER=0
DIALOG="dialog --menu \"Choose Your Web Browser:\" $DLENGTH 35 $N"
for i in $APPMENU; do
  let "COUNTER+=1"
  DIALOG="$DIALOG $COUNTER $i"
done
# See this tutorial on how this works:
# http://linuxcommand.org/lc3_adv_dialog.php
exec 3>&1
BROWSER=$(eval $DIALOG 2>&1 1>&3)
exec 3>&-

case $BROWSER in
 "")
     # The user wants to Cancel the Operation
     exit
     ;;
  1)
     # The user chose Native
     Native
     ;;
  *) 
     # The user chose a browser
     APPLICATION=$( echo $APP | awk "{print \$$BROWSER}" )
     if [ "$APPLICATION" == lftp ]; then
       lftp -c more ${URL}ChangeLog.txt
     else $APPLICATION ${URL}ChangeLog.txt 2>/dev/null
     fi
esac
