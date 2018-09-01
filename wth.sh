#!/bin/bash
# What the hell was I working on (wth):
# ---
# A program that lets you record notes/actions about what you're doing in a
# organized and labeled fashion. Records can then be run/viewed later to see
# your notes. Each record is stored as a bash script so actions can be taken
# when executing the record.

WTH_LOCATION=~/wth
RECORD_NAME="record-`date +%FT%T`"
DEFAULT_NAME="untitled"
PROCESS_STDIN=true

# exec a record
exec_record() {
  grep '^\#.*$' $1
  sh $1
}

RECORD_FULL_PATHS=()
RECORD_FILENAMES=()
RECORD_NAMES=()
RECORD_DATES=()
# Puts all the records and their properties in arrays above
list_records() {
    for f in $WTH_LOCATION/record*.sh
    do
      RECORD_FULL_PATHS+=("$f")
      NAME=`basename "$f"`
      RECORD_FILENAMES+=("$NAME")
      RECORD_NAMES+=("`echo "$NAME" | awk -F '-' '{ print $5 }' \
                     | sed 's/\.sh//'`")
      # echo the full filename, remove the name.sh, replace T in iso std w/ at
      RECORD_DATES+=("`echo "$NAME" | sed 's/record-//' \
                     | sed "s/-${RECORD_NAMES[${#RECORD_NAMES[@]}-1]}.sh//" \
                     | sed 's/T/ at /' | sed 's;-;/;g'`")
    done
}

# Gets the given record name and queries which record if there are duplicates.
# Puts the record name in $RECORDPATH. If the user fails to correctly choose
# a duplicate, returns a empty recordname.
RECORDPATH=''
get_recordname_path() {
    if [ -z "$1" ]; then
      echo "No record name specified"
      exit 1
    fi

    SPECIFIED_NAME=$1
    FOUND_DATES=()
    FOUND=()
    FOUND_PATH=()

    # loop through records
    list_records
    for ((i=0; i<${#RECORD_FILENAMES[@]}; i++)); do

      # check if the name is right
      if [ $SPECIFIED_NAME == ${RECORD_NAMES[$i]} ]; then
        # record the results
        FOUND_DATES+=("${RECORD_DATES[$i]}")
        FOUND+=("${RECORD_NAMES[$i]}")
        FOUND_PATH+=("${RECORD_FULL_PATHS[$i]}")
      fi
    done

    # if could not find record
    if [ ${#FOUND[@]} -eq 0 ]; then
      echo "Could not find specified record name, try running wth.sh -l and" \
           "providing the resulting name shown after the date."
      exit 1

    # if multiple things found
    elif [ ${#FOUND[@]} -gt 1 ]; then
      # there are multiple results, print them out
      echo "Found the following results:"
      for i in "${!FOUND[@]}"; do
        printf '%s: (%s) %s\n' "$i" "${FOUND_DATES[$i]}" "${FOUND[$i]}"
      done

      # ask the user which one they want
      echo "Choose which one to take your action on: "
      read input
      RECORDPATH=${FOUND_PATH[$input]}

    # if there's only one thing found
    elif [ ${#FOUND[@]} -eq 1 ]; then
      RECORDPATH=${FOUND_PATH[0]}
    fi
}

# check for help
if [ "$1" == "--help" ]; then
  echo "usage: wth.sh <recordname-to-open>"
  echo "   or  wth.sh [ -l | -r | -e <recordname>]"
  echo "   or  wth.sh -n <recordname>"
  echo ""
  cat <<EOF
A program that lets you record notes/actions about what you're doing in a
organized and labeled fashion. Records can then be run/viewed later to see
your notes. Each record is stored as a bash script so actions can be taken
when executing the record. Unless given a record name, -l or -r flag,
stdin is processed as a record into a file in ~/wth.
EOF

  echo ""
  echo "optional arguments:"
  echo "    -n, --name            Specifes the name of the new record"
  echo "    -l, --list            Lists all the records"
  echo "    -r, --random          A random record is selected and executed"
  echo "    -e, --edit            Edit a record with the editor specifed in the
                          environment variable \$EDITOR. If the variable is not
                          set, opens in vim."
  exit 0

# if args
elif [ $# -ge 1 ]; then

  # Check if specifying a list of records
  if [ "$1" == "-l" ] || [ "$1" == "--list" ]; then
    list_records  # Set all the arrays that contain record information

    # loop through the records
    for ((i=0; i<${#RECORD_FULL_PATHS[@]}; i++)); do
      # print (date) filename: (record-filename)
      printf "%-23s %-25s %s\n" "(${RECORD_DATES[$i]})" "${RECORD_NAMES[$i]}:" \
             "(${RECORD_FILENAMES[$i]})"

      # print first 2 lines of record
      echo "--------------------------------------------"
      cat "${RECORD_FULL_PATHS[$i]}" | head -3
      echo ""
    done

    PROCESS_STDIN=false  # indicate we shouldn't process stdin

  # If looking to run a random record
  elif [ "$1" == "-r" ] || [ "$1" == "--random" ]; then
    # list the records, randomize it, get the first record
    file=`ls -Gt $WTH_LOCATION/record*.sh | sort -R | tail -1`

    exec_record $file

    PROCESS_STDIN=false  # indicate we shouldn't process stdin

  # If specifying name for record
  elif [ "$1" == "-n" ] || [ "$1" == "--name" ]; then
    # if no second arg
    if [ -z "$2" ]; then
      echo "No record name supplied"
      exit 1
    fi

    # Redefine the name of the record.
    CLEAN=${2//_/}  # strip underscores
    CLEAN=${CLEAN// /_}  # replace spaces with underscores
    CLEAN=${CLEAN//[^a-zA-Z0-9_]/}   # remove all but alphanumeric or underscore
    DEFAULT_NAME="`echo $CLEAN | tr A-Z a-z`"  # convert to lowercase

    # We are expecting stdin, so don't change PROCESS_STDIN

  # If specifying deleting or editing a record
  elif [ "$1" == "-e" ] || [ "$1" == "--edit" ] ||
       [ "$1" == "-d" ] || [ "$1" == "--delete" ]; then
    get_recordname_path $2

    # If specifying to edit
    if [ "$1" == "-e" ] || [ "$1" == "--edit" ]; then
      # edit the record in the default editor
      if [ "$EDITOR" != "" ]; then
        $EDITOR "$RECORDPATH"
      else
        vim "$RECORDPATH"
      fi

    # If specifying to delete
    else
      rm "$RECORDPATH"
    fi

    PROCESS_STDIN=false  # indicate we shouldn't process stdin

  else
    get_recordname_path $1
    if [ "$RECORDPATH" != "" ]; then
      exec_record "$RECORDPATH"

      PROCESS_STDIN=false  # indicate we shouldn't process stdin

    else
      echo "Invalid Arguments. See --help"
      exit 1
    fi
  fi
fi

# if we need to process stdin
if [ "$PROCESS_STDIN" = true ]; then
  # Write out the input to the location and make sure it's executable
  cat >> "$WTH_LOCATION/$RECORD_NAME-$DEFAULT_NAME.sh"
  chmod +x "$WTH_LOCATION/$RECORD_NAME-$DEFAULT_NAME.sh"

  echo "Added record to file: $WTH_LOCATION/$RECORD_NAME-$DEFAULT_NAME.sh"
  exit 0
fi
