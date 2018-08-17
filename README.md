# What the hell was I working on (`wth`):

A dumb program that lets you record what you're doing by piping info into stdin.
Records can be later run/viewed to see/do what you were working on. Input provided is put in it's own script in `~/wth`. Stdin is not sanitized. This is intended such that the recorded bash commands can be run to restore windows and setup your previous work enviroment. Not secure (should be obvious), follows no nonsense design approach.
_In Progress..._

### Recording records:
`wth` takes in stdin that is written to a record in `~/wth`
```bash
$ cat <<EOF | wth.sh
# Should show when shoving -l
# it is a comment since internally it (wth) itemizes records in bash scripts
echo "Command commands in cat to command what Cathy calculated"
python3 -c "print(5 / 2)"
EOF
```

You can/should name your record using the `-n` or `--name` option:

```bash
$ "echo \"Walter was wondering whatever... \"" | wth.sh -n "Wonder Whatever"
Added record to file: ~/wth/record-2018-08-15T10:15:05-wonder_whatever.sh
```

### Observing Output
You can see the records recorded using `wth.sh -l` or `wth.sh --list`. Preview of records is capped at 3. Lines are not executed.
```bash
$ wth.sh -l
(2018/08/15 at 10:14:35) untitled:            (record-2018-08-15T10:14:35-untitled.sh)
--------------------------------------------
# Should show when shoving -l
# it is a comment since internally it (wth) itemizes records in sh scripts
echo "Command commands in cat to command what Cathy calculated"

(2018/08/15 at 10:15:05) wonder_whatever:      (record-2018-08-15T10:15:05-wonder_whatever.sh)
--------------------------------------------
echo "Walter was wondering whatever... "

```

### Exact Execution
You can run a specific record by it's name using `wth -e name`, where name is the name of the record. Comments inside the program are printed out. If there are duplicates, a prompt will popup with your options. Listing a record `-l` can help you find which record you want.
```bash
$ wth.sh -e wonder_whatever
Walter was wondering whatever...
```
(Records are stored as sh scripts, meaning you can run them like any other)
```bash
$ /bin/bash ~/wth/record-2018-08-15T01:12:03-wonder_whatever.sh
Walter was wondering whatever...
```

### Randomly Running
If you want to launch a random record, you can do so by running `wth.sh -r` or `wth.sh --random`. Doing so will result in a random record being executed. Comments inside the program are also printed out.
```bash
$ wth.sh -r
# Should show when shoving -l
# it is a comment since internally it (wth) itemizes records in sh scripts
Command commands in cat to command what Cathy calculated
2.5
```

### Contributing
`wth` is simple and dumb. Help make it better by opening issues and submitting merge requests. You know the deal.


And also, I am awful at alliteration.
