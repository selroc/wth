# What the hell was I working on (`wth`):

A program that lets you record notes/actions about what you're doing in a organized and labeled fashion. Records can then be executed/viewed later to see your notes. Each record is stored as a bash script so it can be executed. This requires notes to start with a `#` at the front.

### Skip the fluff:
`wth.sh --help`

### Recording Records:
`wth` takes in stdin that is written to a record in `~/wth`
```bash
$ cat <<EOF | wth.sh
# I like to put titles here.
# This is a comment since wth stores records in bash scripts (so you can run them)
echo "Command commands in cat to command what Cathy calculated"
python -c "print(5 / 2.0)"
EOF
Added record to file: /Users/dylngg/wth/record-2018-08-31T23:33:01-untitled.sh
```

You can/should name your record using the `-n` or `--name` option:

```bash
$ "echo \"Walter was wondering whatever... \"" | wth.sh -n "Wonder Whatever"
Added record to file: ~/wth/record-2018-08-15T10:15:05-wonder_whatever.sh
```

You can also tag your records for better organization (MacOS Only). Tags are seperated by commas:
```bash
$ "echo \"Walter was wondering whatver... \"" | wth.sh -n "Wonder Whatever" -t wondering,whatever
Added the following tags to the file: wondering, whatever
```

### Listing your Records
You can see the records listed using `wth.sh -l` or `wth.sh --list`. Preview of records is capped at 3. Lines are not executed.
```bash
$ wth.sh -l
(2018/08/15 at 10:14:35) untitled:            (record-2018-08-15T10:14:35-untitled.sh)
--------------------------------------------
# I like to put titles here.
# This is a comment since wth stores records in bash scripts (so you can run them)
echo "Command commands in cat to command what Cathy calculated"

(2018/08/15 at 10:15:05) wonder_whatever:     (record-2018-08-15T10:15:05-wonder_whatever.sh)
--------------------------------------------
echo "Walter was wondering whatever... "

```

You can also filter out records that don't contain any of specified tags. Multiple tags results in showing all records that contain any of the singular tags, as apposed to records with all those tags.
```bash
$ wth.sh -l -t whatever
(2018/08/15 at 10:15:05) wonder_whatever:     (record-2018-08-15T10:15:05-wonder_whatever.sh)
--------------------------------------------
echo "Walter was wondering whatever... "

```

### Executing records
You can run a specific record by it's name using `wth recordname`, where recordname is the name of the record to execute. Comments inside the program are printed out. If there are duplicates, a prompt will popup with your options. Listing a record with `-l` can help you find which record you want.
```bash
$ wth.sh wonder_whatever
Walter was wondering whatever...
```
(Records are stored as sh scripts in ~/wth by default, meaning you can run them like any other bash script)
```bash
$ /bin/bash ~/wth/record-2018-08-15T01:12:03-wonder_whatever.sh
Walter was wondering whatever...
```

### Editing records
You can edit a existing record by doing `wth -e recordname`, where recordname is (you guessed it), the name of the record you want to edit. It opens the record in whatever editor is set in `$EDITOR`. If that enviroment variable is not set, it opens the record in vim. You can add the following to your shell configuration (`~/.bashrc`): `export EDITOR="vim"` to set one. If there are duplicates, a prompt will popup with your options. You can also use `*` to edit all duplicates.
```
$ wth -e wonder_whatever
```

### Editing tags (MacOS Only)
To use tags, you must have [tag]()https://github.com/jdberry/tag installed (`brew install tag`). You can then append specific tags to a record by using `wth.sh -e recordname -t tagtoappend`, where the tags you want to append are seperated by a comma. As well as appending tags, you can also delete specific tags by doing `wth.sh -d recordname -t tagtodelete`.
```
$ wth -d untitled -t useless,todo
```

### Deleting records
You can delete records two ways: using `wth -d name` or by manually deleting a record in ~/wth. If there are duplicates, a prompt will popup with your options. You can also use `*` to delete all duplicates.
```bash
$ wth.sh -d untitled
```

### Randomly executing records
If you want to launch a random record, you can do so by running `wth.sh -r` or `wth.sh --random`. Doing so will result in a random record being executed. Comments inside the program are also printed out. Adding a -t with tags following the flag causes records to only execute if it matches any of the tags.
```bash
$ wth.sh -r
# I like to put titles here.
# This is a comment since wth stores records in bash scripts (so you can run them)
Command commands in cat to command what Cathy calculated
2.5
```


### Contributing
`wth` is simple and dumb. Help make it better by opening issues and submitting merge requests. I have no contribution guidelines or rules besides being respectful. You know the deal. Contributions of all kinds are appreciated.
