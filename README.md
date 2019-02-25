# wth: What the hell... was I working on?

A program that lets you record notes/actions about what you're doing in a organized and labeled fashion. Records can then be executed/viewed later to see your notes. Each record is stored as a bash script so it can be executed. This requires non executable notes to start with a `#`.

## Skip the fluff:

```bash
$ wth.sh --help
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
                          environment variable $EDITOR (Defaults to vim).
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
```

## Basic usage

### Creating a new record

```bash
$ wth.sh recordname -e
Added record to file: /Users/dylngg/wth/record-2019-01-06T15:19:50-recordname.sh
```

This opens the record in your default terminal editor (defaults to vim if not set). You can then write stuff like this:

```bash
# Working on ...
xdg-open ~/Documents/importantDoc.txt
# Left off at this point
firefox https://duckduckgo.com
```

The goal is to write a script that you'll execute later to get back to what you were doing.

### Executing your record

It's a simple as

```bash
$ wth.sh recordname
# Working on ...
# Left off at this point
```

_*That important doc and duckduckgo.com were opened_

### Viewing your records

```bash
$ wth.sh -l
(2019/01/06 at 15:19:50) recordname:
---
# Working on ...
xdg-open ~/Documents/importantDoc.txt
# Left off at this point

(2019/01/06 at 15:19:50) some_other_record:
---
# At some point you put this in.
echo "Hello Again!"

$
```

### Editing your record at a later point

```bash
$ wth.sh recordname -e
```

This opens the record in your editor again.

### Deleting your record

```bash
$ wth.sh recordname -d
```

Self explanatory.

## Further Usage

### Using stdin

You can create records from stdin using the `-S` flag.
```bash
$ cat <<EOF | wth.sh anotherrecord -S
# This is a record created from stdin
echo "Done!"
EOF
Added record to file: /Users/dylngg/wth/record-2019-01-06T15:19:50-anotherrecord.sh
$
```

### Adding and overriding tags (macOS)

This feature requires that [tag](https://github.com/jdberry/tag) is installed (`brew install tag`). This is macOS only due to limited support for tags in other Unix distributions. "tag" is required since Apple doesn't have a nice way of setting tags.

#### Adding tags

```bash
$ wth.sh recordname -a tag
Appended the following tags on recordname: tag
```

The example above appends a tag to the record. You can then see that tag in the `wth.sh -l` output.

#### Overriding tags

```bash
$ wth.sh recordname -s overrides,existing,tags
Set the following tags on recordname: overrides,existing,tags
```

The example above sets the record to contain the following tags. Additional tags must be comma seperated with no space after the commas.

## Contributing

Contributions are welcome. Go ahead and make a issue for things that are broken or for new ideas. Tag it with the appropriate default tags. Attach a pull request if desired.
