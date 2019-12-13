import compileall
import glob
import os
import re

from invoke import run, task

from . import copy


@task
def compile_(ctx):
    print("======================= compile ========================")
    print("------- Compile all .py files (syntax check test) ------")
    rgx = re.compile(r"/virtualenv|virtualenv-osx|virtualenv-py3|.tox|.git|.venv-st2devbox")
    if not compileall.compile_dir(".", rx=rgx, quiet=True):
        raise Exception("Could not compile all files")


@task
def license(ctx):
    # Verifies repo contains LICENSE file with ASF 2.0 content
    print("")
    print("==================== license-check ====================")
    print("")
    apache_license_rgx = re.compile(r'.*Apache License.*')
    license_version_rgx = re.compile(r'.*Version 2\.0.*')
    apache_url_rgx = re.compile(r'.*www\.apache\.org/licenses/LICENSE-2\.0.*')
    files = []
    top_level_git_dir = ctx.run('git rev-parse --show-toplevel').stdout.splitlines()[0]
    base_branch = os.environ.get('BASE_BRANCH', 'origin/master')
    license_file = os.path.join(top_level_git_dir, 'LICENSE')
    with ctx.cd(top_level_git_dir):
        files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                        "--name-only {}".format(base_branch)).stdout.splitlines()
    if os.environ.get('FORCE_CHECK_ALL_FILES', False) == 'true' or files:
        # Check for the existence of a LICENSE file
        if not os.path.exists(license_file):
            raise Exception("Missing LICENSE file in {root_dir}".format(root_dir=top_level_git_dir))

        with open(license_file) as f:
            lines = f.read().splitlines()

        found_apache_license = False
        found_license_version = False
        found_apache_url = False
        for line in lines:
            if apache_license_rgx.match(line):
                found_apache_license = True
            if license_version_rgx.match(line):
                found_license_version = True
            if apache_url_rgx.match(line):
                found_apache_url = True
            if found_apache_license and found_license_version and found_apache_url:
                break
        else:
            raise Exception("LICENSE file doesn't contain Apache 2.0 license text")
    else:
        print("No files have changed, skipping run...")


@task(copy.copy_pack_to_subdirectory)
def configs(ctx):
    print("")
    print("==================== configs-check ====================")
    print("")

    #
    # YAML FILES
    #
    yaml_files = []
    top_level_git_dir = ctx.run('git rev-parse --show-toplevel').stdout.splitlines()[0]
    base_branch = os.environ.get('BASE_BRANCH', 'origin/master')
    with ctx.cd(top_level_git_dir):
        yaml_files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                             "--name-only {} -- '*.yaml' '*.yml'".format(base_branch)).stdout.splitlines()
    if os.environ.get('FORCE_CHECK_ALL_FILES', False) == 'true':
        for yaml_file in glob.glob("**.yaml", recursive=True) + glob.glob("**.yml", recursive=True):
            ctx.run("st2-check-validate-yaml-file {yaml_file}".format(yaml_file=yaml_file))
    elif yaml_files:
        for yaml_file in yaml_files:
            ctx.run("st2-check-validate-yaml-file {yaml_file}".format(yaml_file=yaml_file))
    else:
        print("No files have changed, skipping run...")

    #
    # JSON FILES
    #
    json_files = []
    with ctx.cd(top_level_git_dir):
        json_files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                        "--name-only {} -- '*.json'".format(base_branch)).stdout.splitlines()
    if os.environ.get('FORCE_CHECK_ALL_FILES', False) == 'true':
        for json_file in glob.glob("**.json", recursive=True):
            ctx.run("st2-check-validate-json-file {json_file}".format(json_file=json_file))
    elif json_files:
        for json_file in json_files:
            ctx.run("st2-check-validate-json-file {json_file}".format(json_file=json_file))
    else:
        print("No files have changed, skipping run...")

    #
    # EXAMPLE CONFIG CHECK
    #
    print("")
    print("==================== example config check ====================")
    print("")
    files = []
    with ctx.cd(top_level_git_dir):
        files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                        "--name-only {}".format(base_branch)).stdout.splitlines()
    if os.environ.get('FORCE_CHECK_ALL_FILES', False) == 'true' or files:
        ctx.run("st2-check-validate-pack-example-config "
                "/tmp/packs/{pack_name}".format(pack_name=os.environ['PACK_NAME']))
    else:
        print("No files have changed, skipping run...")


@task
def metadata(ctx):
    print("")
    print("==================== metadata-check ====================")
    print("")
    top_level_git_dir = ctx.run('git rev-parse --show-toplevel').stdout.splitlines()[0]
    base_branch = os.environ.get('BASE_BRANCH', 'origin/master')
    files = []
    files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                    "--name-only {}".format(base_branch)).stdout.splitlines()
    if os.environ.get('FORCE_CHECK_ALL_FILES', False) == 'true' or files:
        ctx.run("st2-check-validate-pack-metadata-exists {pack_dir}".format(pack_dir=top_level_git_dir))
    else:
        print("No files have changed, skipping run...")
