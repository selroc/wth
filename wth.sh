#!/bin/bash
# What the hell was I working on (wth):
# ---
# A dumb program that lets you record what you're doing by piping info into
# stdin. Records can be later run/viewed to see/do what you were working on.
# First line must start with a "#" and typically contain a brief description.
# Each individual input is put in it's own script in a specified location.
# Stdin is not  sanitized. This is intended such that the recorded bash
# commands can be run  to restore windows and setup your previous work env.
# Not secure (duh.), use with extreme caution.

WTH_LOCATION=~/wth
RECORD_NAME="record-`date +%FT%T`"
NAME="untitled"
PROCESS=0

# exec a record
exec_record() {
  grep '^\#.*$' $1
  sh $1
}

# check for help
if [ "$1" == "--help" ]
then
  echo "usage: wth.sh [-l | -r | -n | -e]"
  echo ""
  cat <<EOF
Records commands and comments into a bash file that can be retrieved to
restore what you were working on. Unless -l or -r args are provided, stdin is
processed as a record into a file in ~/wth. Stdin is not sanitized.
EOF

  echo ""
  echo "optional arguments:"
  echo "    -n, --name            name of the record"
  echo "    -l, --list            list all the records in ~/wth"
  echo "    -r, --random          A random record is selected and executed"
  echo "    -e, --execute         Execute a record based on it's name"
  exit 0

# if args
elif [ $# -ge 1 ]
then
  if [ "$1" == "-l" ] || [ "$1" == "--list" ]
  then
    # loop through the records
    for f in $WTH_LOCATION/record*.sh
    do
      RECORD_FN=`basename "$f"`
      FN=`echo "$RECORD_FN" | awk -F '-' '{ print $5 }' | sed 's/\.sh//'`
      RECORD_DATE=`echo "$RECORD_FN" | sed 's/record-//' | sed "s/-$FN.sh//" \
                   | sed 's/T/ at /' | sed 's;-;/;g'`

      # print filename: (record-filename)
      printf "%-23s %-25s %s\n" "($RECORD_DATE)" "$FN:" "($RECORD_FN)"

      # print first 2 lines of record
      echo "--------------------------------------------"
      cat $f | head -3
      echo ""
    done

    PROCESS=1  # indicate we shouldn't process stdin

  # if looking to run a random record
  elif [ "$1" == "-r" ] || [ "$1" == "--random" ]
  then
    # list the records, randomize it, get the first record
    file=`ls -Gt $WTH_LOCATION/record*.sh | sort -R | tail -1`

    exec_record $file

    PROCESS=1  # indicate we shouldn't process stdin

  # if specifying name for record
  elif [ "$1" == "-n" ] || [ "$1" == "--name" ]
  then
    # if no second arg
    if [ -z "$2" ]
    then
      echo "No record name supplied"
      exit 1
    fi

    # Redefine the name of the record.
    # strip underscores
    CLEAN=${2//_/}
    # replace spaces with underscores
    CLEAN=${CLEAN// /_}
    # clean out anything that's not alphanumeric or an underscore
    CLEAN=${CLEAN//[^a-zA-Z0-9_]/}
    # convert to lowercase
    NAME="`echo $CLEAN | tr A-Z a-z`"

  # if specifying execute a record
  elif [ "$1" == "-e" ] || [ "$1" == "--execute" ] ||
       [ "$1" == "-d" ] || [ "$1" == "--delete" ]
  then
    if [ -z "$2" ]
    then
      echo "No record name specified"
      exit 1
    fi

    SPECIFIED_NAME=$2
    FOUND_DATES=()
    FOUND=()
    FOUND_PATH=()

    # loop through results
    for f in $WTH_LOCATION/record*.sh
    do
      RECORD_FN=`basename "$f"`
      FN=`echo "$RECORD_FN" | awk -F '-' '{ print $5 }' | sed 's/.sh//'`
      DATE=`echo "$RECORD_FN" | sed 's/record-//' | sed "s/-$FN.sh//g" \
            | sed 's/T/ at /' | sed 's;-;/;g'`

      # check if the name is right
      if [ $SPECIFIED_NAME == $FN ]
      then
        # record the results
        FOUND_DATES+=($DATE)
        FOUND+=($FN)
        FOUND_PATH+=($f)
      fi
    done

    # if could not find record
    if [ ${#FOUND[@]} -eq 0 ]
    then
      echo "Could not find specified record name, try running wth.sh -l and" \
           "providing the resulting name shown after the date"
      exit 1

    # if multiple things found
    elif [ ${#FOUND[@]} -gt 1 ]
    then
      # there are multiple results, print them out
      echo "Found the following results:"
      echo "--------------------------------------------"
      echo ""
      for i in "${!FOUND[@]}"
      do
        printf '%s: (%s) %s\n\n' "$i" "${DATES[$i]}" "${FOUND[$i]}"
      done

      # ask the user which one they want
      echo "Choose which one to execute: "
      read input
      TO_EXEC=${FOUND_PATH[$input]}

    # if there's only one thing found
    elif [ ${#FOUND[@]} -eq 1 ]
    then
      TO_EXEC=${FOUND_PATH[0]}
    fi

    if [ "$1" == "-e" ] || [ "$1" == "--execute" ]
    then
      # execute the record
      exec_record "$TO_EXEC"
    else
      rm "$TO_EXEC"
    fi

    PROCESS=1  # indicate we shouldn't process stdin

  else
    echo "Invalid Arguments. See --help"
    exit 1
  fi
fi

# if we need to process stdin
if [ $PROCESS -eq 0 ]
then
  cat >> $WTH_LOCATION/$RECORD_NAME-$NAME.sh
  chmod +x $WTH_LOCATION/$RECORD_NAME-$NAME.sh
  echo "Added record to file: $WTH_LOCATION/$RECORD_NAME-$NAME.sh"
  exit 0
fi
