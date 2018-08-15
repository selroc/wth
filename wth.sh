#!/bin/bash
# What the hell was I working on (wth):
# ---
# A dumb program that lets you record what you're doing by piping info into 
# stdin. Records can be later run/viewed to see/do what you were working on. 
# First line must start with a "#" and typically contain a brief description.
# Each individual input is put in it's own script in ~/wth. Stdin is not 
# sanitized. This is intended such that the recorded bash commands can be run to
# restore windows and setup your previous work env. Not secure (duh.), use with 
# extreme caution. 


RECORD_NAME="record-`date +%FT%T`"
PROCESS=0

if [ "$1" == "--help" ]
then
  echo "usage: wth.sh [-l | -r | -n]"
  echo ""
  echo "Records commands and comments into a bash file that can be retrieved to restore what you were working on. Unless -l or -r args are provided, stdin is processed as a record into a file in ~/wth. Stdin is not sanitized. Requires sudo privilages."
  echo ""
  echo "optional arguments:"
  echo "    -n, --name            name of the record"
  echo "    -l, --list            list all the records in ~/wth"
  echo "    -r, --random          A random record is selected and executed"
  exit 0

elif [ $# -gt 1 ] 
then
  if [ "$1" == '-l' ] || [ "$1" == '--list' ]
  then
    # list the records
    ls -Gt ~/wth/record*.sh
    PROCESS=1
  elif [ "$1" == '-r' ] || [ "$1" == '--random' ]
  then
    # list the records, randomize it, get the first record
    file=`ls -Gt ~/wth/record*.sh | sort -R | tail -1`
    while read -r line
    do 
      if [[ ${line:0:1} == "#" ]]
      then
        # if a comment, print the line
        echo $line
      else
        # otherwise, execute the line
        $line
      fi 
    done < $file

    PROCESS=1  # indicate that we are not processing input
 
  elif [ "$1" == '-n' ] || [ "$1" == '--name' ]
  then
    # if no second arg
    if [ -z "$2" ]
    then
      echo "No name supplied"
      exit 1
    fi
    
    # Redefine the name of the record.
    # strip underscores
    CLEAN=${2//_/}
    # replace spaces with underscores
    CLEAN=${CLEAN// /_}
    # clean out anything that's not alphanumeric or an underscore
    CLEAN=${CLEAN//[^a-zA-Z0-9_]/}
    # lowercase with TR
    RECORD_NAME="$RECORD_NAME-`echo $CLEAN | tr A-Z a-z`"
  else
    echo "Invalid Arguments. See --help"
  fi
fi
if [ $PROCESS -eq 0 ]
then
  while read stdin
  do
    # write the input out to the record
    echo $stdin > ~/wth/$RECORD_NAME.sh
  done
  echo "Added record to file: ~/wth/$RECORD_NAME.sh"
  exit 0
fi
