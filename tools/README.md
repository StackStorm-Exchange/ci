# Tools for Exchange packs

## copyright-update.py

This tool is used to insert and update copyright headers into the following:
* Python files
* LICENSE files (Apache only for now)
* README.md files (only used in StackStorm/st2/README.md for now)

### Useage 

To update all of the files in a repo it's as simple as:

```bash
# default directory is pwd
ci/copyright_update.py

# use a specific directory
ci/copyright_update.py -d path/to/git/repo
```

This will recursively find all of the files and make updates, printing out when it makes a change.

If you want to specify a custom year, or range of years you can pass the `-y/--year` option

```bash
# single year
ci/copyright_update.py -y 2021

# range of years
ci/copyright_update.py -y 2020-2021
```

This script only writes the files, it doesn't do any git commits or pushes, that will need to be
orchestrated at a different layer.
