#!/bin/bash
value=$( grep -ic "postfixJ" /etc/passwd )
if [ $value -eq 1 ]
then
  echo "I found postfix"
else
  echo "I didn't find postfix"
fi
