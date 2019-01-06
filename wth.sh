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


# Puts all the records and their properties in arrays below
place_record_metadata() {
  RECORD_FULL_PATHS=()
  RECORD_FILENAMES=()
  RECORD_NAMES=()
  RECORD_DATES=()
  search_method=`ls -1 $WTH_LOCATION/record*.sh`
  if [ ! -z "$1" ] && command -v tag > /dev/null; then
      search_method=`tag -m "$1" ~/wth/record*.sh`
  fi

  for f in $search_method; do
    local name=`basename "$f"`
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
  local clean=${1//_/}  # strip underscores
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
    local full_path=${RECORD_FULL_PATHS[$i]}
    local tags=""

    if command -v tag > /dev/null; then
      tags="`tag -lN $full_path`"
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
get_recordname_path() {
  RECORDNAME_PATH=""
  if [ -z "$1" ]; then
    echo "No record name specified"
    exit 1
  fi

  local found_dates=()
  local found_names=()
  local found_paths=()

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
    echo "Could not find record $1, try running wth.sh -l and providing" \
          "the resulting name shown after the date."
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
    elif [ ! -z ${found_paths[$input]} ]; then
        RECORDNAME_PATH=${found_paths[$input]}
    else
      echo "Not valid selection, quiting."
      exit 1
    fi

  # if there's only one thing found
  else
    RECORDNAME_PATH=${found_paths[0]}
  fi
}

elementIn() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

print_help() {
  cat <<EOF
usage: wth.sh <recordname-to-open>
   or  wth.sh <recordname-to-modify> [flags] <tags>
   or  wth.sh <recordname-to-modify> [modifier]
   or  wth.sh <recordname-to-modify> [modifier] [flags] <tags>
   or  wth.sh [action]
   or  wth.sh [action] <tags>

A program that lets you record bash scripts about what you're doing in a
organized and labeled fashion. Records can then be executed later to see your
commented notes.

modifiers:
    -e, --edit            Edit/creates a record with the editor specifed in the
                          environment variable \$EDITOR (Defaults to vim).
    -d, --delete          Removes the record.
    -S, --stdin           Append stdin into the existing or new record.

actions:
    -l, --list <tags>     Lists all the records matching the optional following
                          tags. Following arguments modify all listed.
    -h, --help            Prints out help.

optional flags:
    -a, --append <tags>   Appends the following comma separated tags to the
                          item(s) on the left.
    -s, --set <tags>      Overrides the following comma separated tags to the
                          item(s) on the left. A empty argument will remove all
                          of the tags.
EOF
}


MODIFIERS=(-e --edit -d --delete -S --stdin)
ACTIONS=(-l --list -h --help)
FLAGS=(-a --append -s --set)

if elementIn "$1" "${ACTIONS[@]}"; then
  case "$1" in
    "--help" | "-h")
      print_help
      exit 0
      ;;
    "--list" | "-l")
      list_records ${@:2}
      exit 0
      ;;
  esac

elif elementIn $2 "${MODIFIERS[@]}" || elementIn $2 "${FLAGS[@]}"; then
  RECORD_NAME=$1

  case "$2" in
    "--edit" | "-e")
      get_recordname_path $RECORD_NAME
      # edit the record in the default editor
      if [ "$EDITOR" != "" ]; then
        $EDITOR `echo $RECORDNAME_PATH`
      else
        vim `echo $RECORDNAME_PATH`
      fi
      shift
      ;;
    "--delete" | "-d")
      get_recordname_path $RECORD_NAME
      rm $RECORDNAME_PATH
      exit 0
      ;;
    "--stdin" | "-S")
      cat >> "$WTH_LOCATION/$RECORD_PREFIX-$RECORD_NAME.sh"
      chmod +x "$WTH_LOCATION/$RECORD_PREFIX-$RECORD_NAME.sh"
      echo "Added record to file: $WTH_LOCATION/$RECORD_PREFIX-$RECORD_NAME.sh"
      shift
      ;;
  esac

  # append or set the tags
  if elementIn $2 "${FLAGS[@]}"; then
    if ! command -v tag > /dev/null; then
      echo "`tag` is not installed on this machine (tag is only on MacOS)"
    fi
    tags="${@:3}"
    get_recordname_path $RECORD_NAME

    case "$2" in
      "--append" | "-a")
        tag -a $tags $RECORDNAME_PATH
        echo "Appended the following tags on $RECORD_NAME: $tags"
        ;;
      "--set" | "-s")
        tag -s $tags $RECORDNAME_PATH
        echo "Set the following tags on $RECORD_NAME: $tags"
        ;;
    esac
  fi
  exit 0

else
  get_recordname_path $1
  if [ "$RECORDNAME_PATH" != "" ]; then
    exec_record "$RECORDNAME_PATH"
    exit 0
  else
    echo -e "${RED}Invalid Arguments. See --help${CLEAR}"
    exit 1
  fi

fi
