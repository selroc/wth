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
COLOR=true

# Show color if terminal is defined and color is true
if [ ! -z ${TERM+x} ] || [ "$TERM" != "" ] && $COLOR; then
  GRAY='\033[0;37m'
  GREEN='\033[0;32m'
  RED='\033[0;31m'
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
        SEARCH_METHOD=`tag -m "$1" ~/wth/record*.sh`
    else
        SEARCH_METHOD=`ls -1 $WTH_LOCATION/record*.sh`
    fi
    for f in $SEARCH_METHOD; do
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

# Strips a given name to remove unwanted characters and returns it
strip_name() {
  # Redefine the name of the record.
  CLEAN=${1//_/}  # strip underscores
  CLEAN=${CLEAN// /_}  # replace spaces with underscores
  CLEAN=${CLEAN//[^a-zA-Z0-9_]/}   # remove all but alphanumeric or underscore
  echo "`echo $CLEAN | tr A-Z a-z`"  # convert to lowercase
}

# Returns whether the given tags associated with a file contain any given tags
# given in the tags to match.
inTags() {
  IFS=',' read -ra TAGS_WANTED <<< "$2"
  IFS=',' read -ra TAGS_GIVEN <<< "$1"

  for given_tag in "${TAGS_GIVEN[@]}"; do
    if elementIn "`echo $given_tag | xargs`" "${TAGS_WANTED[@]}"; then
      return 0
    fi
  done

  return 1
}

# Returns whether a given tag matches any given array of tags.
elementIn() {
  local tag match="$1"
  shift
  for tag; do [[ "$tag" == "$match" ]] && return 0; done
  return 1
}


# Prints out the records ordered by date, giving the recordname and a preview.
# If tags are given, records are filtered such that they must match one of the
# tags
PREVIEW_LENGTH=3
list_records() {
  # Set all the arrays that contain record information
  place_record_metadata $1

  for ((i=0; i<${#RECORD_FULL_PATHS[@]}; i++)); do
    # if record tags contain any specified tags if applicable
    printf "%-23s ${GREEN}%-25s${CLEAR}\n" "(${RECORD_DATES[$i]})" "${RECORD_NAMES[$i]}:"

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
get_recordname_path() {
    if [ -z "$1" ]; then
      echo "No record name specified"
      exit 1
    fi

    NEW_RECORD_PATH=""
    SPECIFIED_NAME=$1
    FOUND_DATES=()
    FOUND=()
    FOUND_PATH=()

    # loop through records and see if we can find the one specified
    place_record_metadata
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
      if [ "$input" = "*" ]; then
          NEWRECORDPATH="${FOUND_PATH[*]}"
      else
          NEW_RECORD_PATH=${FOUND_PATH[$input]}
      fi

    # if there's only one thing found
    elif [ ${#FOUND[@]} -eq 1 ]; then
      NEW_RECORD_PATH=${FOUND_PATH[0]}
    fi

    echo $NEW_RECORD_PATH
}

print_help() {
  cat <<EOF
usage: wth.sh <recordname-to-open>
   or  wth.sh [ -l | -r | -e <recordname>]
   or  wth.sh [ -l | -r | -e <recordname>] -t <tag>, <tag2> ...
   or  wth.sh -n <recordname> -t <tag>, <tag2> ...
   or  wth.sh -n <recordname>

A program that lets you record notes/actions about what you're doing in a
organized and labeled fashion. Records can then be run/viewed later to see
your notes. Each record is stored as a bash script so actions can be taken
when executing the record. Unless given a record name to execute, -l, -e or -r
flag, stdin is processed as a record into a file in ~/wth. A -t added to the
end end of any of the optional arguments causes tags to be added, or refines
the results of the optional argument.

optional arguments:
    -n, --name            Specifes the name of the new record. If -t is
                          invoked, the following tags are added.
    -l, --list            Lists all the records. If -t is invoked, refines the
                          results returned to show those with any of the given
                          tags.
    -r, --random          A random record is selected and executed. If -t is
                          invoked, only records with any of the given tags will
                          be selected.
    -e, --edit            Edit a record with the editor specifed in the
                          environment variable \$EDITOR. If the variable is not
                          set, opens in vim. If -t is invoked, the following
                          tags are added and the record is not opened.
    -t, --tags            MacOS Only. Sets/refines the following tags to the
                          argument to the left of it. The -t flag must occur
                          last in the arguments. Tags must be comma seperated.
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

  # If looking to run a random record
  elif [ "$1" == "-r" ] || [ "$1" == "--random" ]; then
    # list the records, randomize it
    POSSIBLE_FILES=`ls -Gt $WTH_LOCATION/record*.sh | sort -R`
    file=""

    for f in POSSIBLE_FILES; do
      # get the first record that matches any of the tags
      if inTags "$f" "$TAGS"; then
        exec_record $file
      fi
    done

    if [ "$file" == "" ]; then
      echo "Could not find any files with the following tags: $TAGS"
      exit 1
    fi
    exit 0

  # If specifying deleting or editing a record
  elif [ "$1" == "-e" ] || [ "$1" == "--edit" ] ||
       [ "$1" == "-d" ] || [ "$1" == "--delete" ]; then
    RECORDPATH=$(get_recordname_path $2)

    # If specifying to edit
    if [ "$1" == "-e" ] || [ "$1" == "--edit" ]; then

      # edit the tags
      if [ "$TAGS" != "" ] && command -v tag > /dev/null; then
        tag -a $TAGS "$RECORDPATH"
        echo "Added the following tags: $TAGS"

      # edit the record in the default editor
      elif [ "$EDITOR" != "" ]; then
        $EDITOR `echo $RECORDPATH`
      else
        vim `echo $RECORDPATH`
      fi

    # If specifying to delete
    elif [ "$TAGS" != "" ] && command -v tag; then
      tag -r $TAGS "$RECORDPATH"

    else
      rm `echo $RECORDPATH`
    fi
    exit 0

  # If specifying name for record
  elif [ "$1" == "-n" ] || [ "$1" == "--name" ]; then
    # if no second arg
    if [ -z "$2" ]; then
      echo -e "${RED}No record name supplied${CLEAR}"
      exit 1
    fi

    DEFAULT_NAME=$(strip_name $2)

  else
    if [ "$2" == "" ]; then
        echo -e "${RED}No Arguments Provided. See --help${CLEAR}"
        exit 1
    fi

    RECORDPATH=$(get_recordname_path $1)
    if [ "$RECORDPATH" != "" ]; then
      exec_record "$RECORDPATH"
      exit 0

    else
      echo -e "${RED}Invalid Arguments. See --help${CLEAR}"
      exit 1
    fi
  fi
fi

# Write out the input to the location and make sure it's executable
cat >> "$WTH_LOCATION/$RECORD_NAME-$DEFAULT_NAME.sh"
chmod +x "$WTH_LOCATION/$RECORD_NAME-$DEFAULT_NAME.sh"
echo "Added record to file: $WTH_LOCATION/$RECORD_NAME-$DEFAULT_NAME.sh"

if [ "$TAGS" != "" ] && command -v tag > /dev/null; then
  tag -s $TAGS "$WTH_LOCATION/$RECORD_NAME-$DEFAULT_NAME.sh"
  echo "Added the following tags to the file: $TAGS"
fi

exit 0
