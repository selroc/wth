#!/bin/bash
# What the hell was I working on (wth):
# ---
# A program that lets you record notes/actions about what you're doing in a
# organized and labeled fashion. Records can then be run/viewed later to see
# your notes. Each record is stored as a bash script so actions can be taken
# when executing the record.

WTH_LOCATION=~/wth
RECORD_PREFIX="record-`date +%FT%T`"
RECORD_NAME="untitled"
PREVIEW_LENGTH=3
COLOR=true

# Show color if terminal is defined and color is true
if [ ! -z ${TERM+x} ] || [ "$TERM" != "" ] && $COLOR; then
  GRAY='\033[0;37m'
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  BLUE='\033[0;36m'
  CLEAR='\033[0m'
fi

# Exec a record
exec_record() {
  grep '^\#.*$' $1
  sh $1
}

RECORD_FULL_PATHS=()
RECORD_FILENAMES=()
RECORD_NAMES=()
RECORD_DATES=()
# Puts all the records and their properties in arrays above
place_record_metadata() {
    if [ ! -z "$1" ] && command -v tag > /dev/null; then
        search_method=`tag -m "$1" ~/wth/record*.sh`
    else
        search_method=`ls -1 $WTH_LOCATION/record*.sh`
    fi
    for f in $search_method; do
      name=`basename "$f"`
      RECORD_FULL_PATHS+=("$f")
      RECORD_FILENAMES+=("$name")
      RECORD_NAMES+=("`echo "$name" | awk -F '-' '{ print $5 }' \
                     | sed 's/\.sh//'`")
      # echo the full filename, remove the name.sh, replace T in iso std w/ at
      RECORD_DATES+=("`echo "$name" | sed 's/record-//' \
                     | sed "s/-${RECORD_NAMES[${#RECORD_NAMES[@]}-1]}.sh//" \
                     | sed 's/T/ at /' | sed 's;-;/;g'`")
    done
}

# Strips a given name to remove unwanted characters and returns it via echo
strip_name() {
  # Redefine the name of the record.
  clean=${1//_/}  # strip underscores
  clean=${clean// /_}  # replace spaces with underscores
  clean=${clean//[^a-zA-Z0-9_]/}   # remove all but alphanumeric or underscore
  echo "`echo $clean | tr A-Z a-z`"  # convert to lowercase
}

# Prints out the records ordered by date, giving the recordname and a preview.
# If tags are given, records are filtered such that they must match one of the
# tags
list_records() {
  # Set all the arrays that contain record information
  place_record_metadata $1

  for ((i=0; i<${#RECORD_FULL_PATHS[@]}; i++)); do
    full_path=${RECORD_FULL_PATHS[$i]}

    if command -v tag > /dev/null; then
      tags="`tag -lN $full_path | sed 's/, */, /g'`"
    fi
    # if record tags contain any specified tags if applicable
    printf "%-23s ${GREEN}%s${CLEAR}: ${BLUE}%s${CLEAR}\n" "(${RECORD_DATES[$i]})" \
           "${RECORD_NAMES[$i]}" "$tags"

    # print first 2 lines of record
    echo "---"
    while read record; do
      echo -e "${GRAY}$record${CLEAR}"
    done < "${RECORD_FULL_PATHS[$i]}" | head -$PREVIEW_LENGTH
    echo ""
  done
}

# Gets the given record name and queries which record if there are duplicates,
# returning the record path. If the user inputs '*' for the given duplicates,
# returns all valid values. If the user fails to correctly choose a duplicate,
# returns a empty recordname.
RECORDNAME_PATH=""
get_recordname_path() {
    if [ -z "$1" ]; then
      echo "No record name specified"
      exit 1
    fi

    found_dates=()
    found_names=()
    found_paths=()

    # loop through records and see if we can find the one specified
    place_record_metadata
    for ((i=0; i<${#RECORD_FILENAMES[@]}; i++)); do
      if [ $1 == ${RECORD_NAMES[$i]} ]; then
        found_dates+=("${RECORD_DATES[$i]}")
        found_names+=("${RECORD_NAMES[$i]}")
        found_paths+=("${RECORD_FULL_PATHS[$i]}")
      fi
    done

    if [ ${#found_names[@]} -eq 0 ]; then
      echo "Could not find specified record name, try running wth.sh -l and" \
           "providing the resulting name shown after the date."
      exit 1

    elif [ ${#found_names[@]} -gt 1 ]; then
      echo "Found the following results:"
      for i in "${!found_names[@]}"; do
        printf '%s: (%s) %s\n' "$i" "${found_dates[$i]}" "${found_names[$i]}"
      done

      echo "Choose which one to take your action on (* for all above): "
      read input
      if [ "$input" = "*" ]; then
          RECORDNAME_PATH="${found_paths[*]}"
      else
          RECORDNAME_PATH=${found_paths[$input]}
      fi

    # if there's only one thing found
    else
      RECORDNAME_PATH=${found_paths[0]}
    fi
}

print_help() {
  cat <<EOF
usage: wth.sh <recordname-to-open> [modifiers]
   or  wth.sh <recordname-to-open> [modifiers] [flags] <arguments>
   or  wth.sh [action] <arguments>
   or  wth.sh [action] <arguments> [flags] <arguments>

A program that lets you record bash scripts about what you're doing in a
organized and labeled fashion. Records can then be executed later to see your
commented notes.

modifiers:
    -e, --edit            Edit/creates a record with the editor specifed in the
                          environment variable \$EDITOR (Defaults to vim).
    -d, --delete          Removes the record.

actions:
    -n, --name <name>     Pipes stdin into a new record with the following
                          name. Following arguments modify the new record.
    -l, --list <tags>     Lists all the records matching the optional following
                          tags. Following arguments modify all listed.

optional flags:
    -a, --append <tags>   Appends the following comma separated tags to the
                          item(s) on the left.
    -s, --set <tags>      Overrides the following comma separated tags to the
                          item(s) on the left. A empty argument will remove all
                          of the tags.
EOF
}


# check for help
if [ "$1" == "--help" ]; then
  print_help
  exit 0

# if args
elif [ $# -ge 1 ]; then

  # check for tags in the second and third argument
  if [ "$2" == "-t" ] || [ "$2" == "-tags" ]; then
    TAGS="${@:3}"

  elif [ "$3" == "-t" ] || [ "$3" == "-tags" ]; then
    TAGS="${@:4}"
  fi

  # Check if specifying a list of records
  if [ "$1" == "-l" ] || [ "$1" == "--list" ]; then
    list_records $TAGS
    exit 0

  # If specifying deleting or editing a record
  elif [ "$1" == "-e" ] || [ "$1" == "--edit" ] ||
       [ "$1" == "-d" ] || [ "$1" == "--delete" ]; then
    get_recordname_path $2

    # If specifying to edit
    if [ "$1" == "-e" ] || [ "$1" == "--edit" ]; then

      # edit the tags
      if [ "$TAGS" != "" ] && command -v tag > /dev/null; then
        tag -a $TAGS "$RECORDNAME_PATH"
        echo "Added the following tags: $TAGS"

      # edit the record in the default editor
      elif [ "$EDITOR" != "" ]; then
        $EDITOR `echo $RECORDNAME_PATH`
      else
        vim `echo $RECORDNAME_PATH`
      fi

    # If specifying to remove tags
    elif [ "$TAGS" != "" ] && command -v tag; then
      tag -r $TAGS "$RECORDNAME_PATH"

    # If specifying to delete
    else
      rm `echo $RECORDNAME_PATH`
    fi
    exit 0

  # If specifying name for record
  elif [ "$1" == "-n" ] || [ "$1" == "--name" ]; then
    # if no second arg
    if [ -z "$2" ]; then
      echo -e "${RED}No record name supplied${CLEAR}"
      exit 1
    fi
    RECORD_NAME=$(strip_name $2)

  else
    if [ "$2" == "" ]; then
        echo -e "${RED}No Arguments Provided. See --help${CLEAR}"
        exit 1
    fi

    get_recordname_path $1
    if [ "$RECORDNAME_PATH" != "" ]; then
      exec_record "$RECORDNAME_PATH"
      exit 0

    else
      echo -e "${RED}Invalid Arguments. See --help${CLEAR}"
      exit 1
    fi
  fi
fi

# Write out the input to the location and make sure it's executable
cat >> "$WTH_LOCATION/$RECORD_PREFIX-$RECORD_NAME.sh"
chmod +x "$WTH_LOCATION/$RECORD_PREFIX-$RECORD_NAME.sh"
echo "Added record to file: $WTH_LOCATION/$RECORD_PREFIX-$RECORD_NAME.sh"

if [ "$TAGS" != "" ] && command -v tag > /dev/null; then
  tag -s $TAGS "$WTH_LOCATION/$RECORD_PREFIX-$RECORD_NAME.sh"
  echo "Added the following tags to the file: $TAGS"
fi

exit 0
