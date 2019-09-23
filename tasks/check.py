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
