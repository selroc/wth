#!/bin/bash
# TagIt: A program that lets you easily modify or view MacOS tags.

# Given a file, returns all the tags associated with the file
getTags() {
  # return tags seperated by a comma and a space
  echo "`mdls -raw -name kMDItemUserTags $1 | grep -v '(\|)' | xargs`" 
}

# Given a file, sets the given tags seperated by a comma, overriding all 
# current tags
setTags() {
  PLIST_DATA='<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
              "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
              <plist version="1.0"><array>'

  # loop through tags and add them to our plist data
  INPUT="${@:2}"

  IFS=',' read -ra TAGS <<< "$INPUT"
  for tag in "${TAGS[@]}"; do
    PLIST_DATA+="<string>$tag</string>"
  done

  PLIST_DATA+="</array></plist>"
  xattr -w com.apple.metadata:_kMDItemUserTags "$PLIST_DATA" $1
}

if [ "$1" == "--help" ]; then
  cat <<EOF 
usage: tagit.sh <file>
   or  tagit.sh <file> [ -a | -d | -s ] <tag>, <tag2> ...

A program that lets you easily modify or view MacOS tags.

optional arguments:
    -a, --append          Appends the following tags seperated by a comma.
    -s, --set             Sets the following tags, overriding all current tags.
                          Can be used to remove all tags by giving no tags to
                          set. Tags should be seperated by a comma.
    -d, --delete          Deletes the following tags seperated by a comma.
EOF

# check if the file exists
elif [ ! -f "$1" ]; then
  echo "File not found. Exiting..."
  exit 1

# just print the tags belonging to the file
elif [ $# -eq 1 ]; then
  # print the tags
  echo $(getTags $1)

elif [ "$2" == "-a" ] || [ "$2" == "--append" ]; then
  # append the tags, seperated by commas
  TAGS="$(getTags $1)"
  TAGS+=",${@:3}"
  setTags $1 $TAGS

elif [ "$2" == "-d" ] || [ "$2" == "--delete" ]; then
  # delete the tags by removing them from the current list and setting them
  TAGS="$(getTags $1)"

  IFS=',' read -ra TOREMOVE <<< "${@:3}"
  for tag in "${TOREMOVE[@]}"; do
    TAGS=`echo $TAGS | tr , '\n'| grep -v "^$tag$"`
  done

  # set the tags
  setTags $1 `echo $TAGS | tr '\n' ,`

elif [ "$2" == "-s" ] || [ "$2" == "--set" ]; then
  # set the tags
  setTags $1 "${@:3}"

else
  echo "Invalid Arguments. See --help"
  exit 1
fi