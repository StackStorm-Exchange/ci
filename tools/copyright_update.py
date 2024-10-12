#!/usr/bin/env python
from __future__ import print_function
import argparse
import datetime
import glob
import os
import re

# year that StackStorm became a Linux Foundation project
STACKSTORM_LINUX_FOUNDATION_BEGIN = "2020"

# Python file copyrights
COPYRIGHT_PY_ST2_FORMAT = "# Copyright {year} The StackStorm Authors." + os.linesep
COPYRIGHT_PY_ST2_PATTERN = re.compile(
    "# Copyright (?P<year>\\d+(-\\d+)?) The StackStorm Authors\\."
)
COPYRIGHT_PY_ANY_PATTERN = re.compile(
    "# Copyright (?P<year>\\d+(-\\d+)?) (?!The StackStorm Authors\\.).*"
)

# LICENSE file copyrights (Apache specific)
COPYRIGHT_LICENSE_FORMAT = "   Copyright {year} The StackStorm Authors." + os.linesep
COPYRIGHT_LICENSE_PATTERN = re.compile("   Copyright .*")
COPYRIGHT_LICENSE_APACHE_PATTERN = re.compile("                                 Apache License.*")

# README.md copyrights (specific to StackStorm/st2 repo)
COPYRIGHT_README_ST2_FORMAT = "Copyright {year} The StackStorm Authors." + os.linesep
COPYRIGHT_README_ST2_PATTERN = re.compile(
    "Copyright (?P<year>\\d+(-\\d+)?) The StackStorm Authors\\."
)
COPYRIGHT_README_ANY_PATTERN = re.compile(
    "Copyright (?P<year>\\d+(-\\d+)?) (?!The StackStorm Authors\\.).*"
)


def parse_cli_args():
    parser = argparse.ArgumentParser(prog=os.path.basename(__file__))
    parser.add_argument("-d", "--directory", default=".")
    # user current year by default
    year = str(datetime.datetime.now().year)
    # if the current year is > then year we started with Linux foundation, then create
    # a year range: 2020-<current>
    if year != STACKSTORM_LINUX_FOUNDATION_BEGIN:
        year = f"{STACKSTORM_LINUX_FOUNDATION_BEGIN}-{year}"
    parser.add_argument("-y", "--year", default=year)
    return parser.parse_args()


def find_files_by_glob(directory, file_glob):
    found_files = []
    for root, _dirs, _files in os.walk(directory):
        for f in glob.glob(os.path.join(root, file_glob)):
            found_files.append(f)
    return sorted(found_files)


def find_files_by_extension(directory, extension):
    return find_files_by_glob(directory, f"*{extension}")


def find_files_by_name(directory, name):
    return find_files_by_glob(directory, name)


def update_copyright_st2_any(filename, year, st2_pattern, any_pattern, st2_format):
    # read
    with open(filename, "r", encoding="utf-8") as fr:
        lines = fr.readlines()

    # find copyrights
    copyright_str = st2_format.format(year=year)
    any_copyright_lines = []
    st2_copyright_updated = False
    st2_copyright_lines = []
    for idx, line in enumerate(lines):
        if st2_pattern.match(line):
            st2_copyright_lines.append(idx)
            if lines[idx] != copyright_str:
                lines[idx] = copyright_str
                st2_copyright_updated = True
        elif any_pattern.match(line):
            any_copyright_lines.append(idx)

    # write changes
    changed = False
    if st2_copyright_lines:
        # insert StackStorm copyright before the other copyrights
        if st2_copyright_updated:
            print(f"{filename} - updated existing StackStorm copyright")
            with open(filename, "w", encoding="utf-8") as fw:
                fw.writelines(lines)
                changed = True
    elif any_copyright_lines:
        print(f"{filename} - added new StackStorm copyright")
        with open(filename, "w", encoding="utf-8") as fw:
            # insert StackStorm copyright before the other copyrights
            lines.insert(any_copyright_lines[0], copyright_str)
            fw.writelines(lines)
            changed = True
    # else:
    # Ignoring files without copyrights.
    # TODO make an CLI option to add copyrights to files that don't have one
    # # check if file is not empty, then we need to add a copyright
    # # we are ignoring empty files example: blank __init__.py files
    # if os.stat(filename).st_size != 0:
    #     print("{} - No copyright found, inserting one on the first line".format(filename))
    #     with open(filename, 'w') as fw:
    #         lines.insert(0, copyright_str)
    #         fw.writelines(lines)

    return changed


def update_copyright_python(filename, year):
    return update_copyright_st2_any(
        filename, year, COPYRIGHT_PY_ST2_PATTERN, COPYRIGHT_PY_ANY_PATTERN, COPYRIGHT_PY_ST2_FORMAT
    )


def update_copyright_apache_license(filename, year):
    # read
    with open(filename, "r", encoding="utf-8") as fr:
        lines = fr.readlines()

    # find copyrights
    is_apache = False
    updated = False
    for idx, line in enumerate(lines):
        if not is_apache and COPYRIGHT_LICENSE_APACHE_PATTERN.match(line):
            is_apache = True
        elif COPYRIGHT_LICENSE_PATTERN.match(line):
            copyright_str = COPYRIGHT_LICENSE_FORMAT.format(year=year)
            if lines[idx] != copyright_str:
                lines[idx] = copyright_str
                updated = True

    # write changes
    if not is_apache:
        print(f"{filename} - ERROR this is not an Apache license file, ignorning")
    elif updated:
        print(f"{filename} - updated existing copyright")
        with open(filename, "w", encoding="utf-8") as fw:
            fw.writelines(lines)


def update_copyright_readme(filename, year):
    return update_copyright_st2_any(
        filename,
        year,
        COPYRIGHT_README_ST2_PATTERN,
        COPYRIGHT_README_ANY_PATTERN,
        COPYRIGHT_README_ST2_FORMAT,
    )


def run(directory, year):
    # python files
    for f in find_files_by_extension(directory, ".py"):
        update_copyright_python(f, year)

    # license files
    for f in find_files_by_name(directory, "LICENSE"):
        update_copyright_apache_license(f, year)

    # README files
    for f in find_files_by_name(directory, "README.md"):
        update_copyright_readme(f, year)


if __name__ == "__main__":
    args = parse_cli_args()
    run(args.directory, args.year)
