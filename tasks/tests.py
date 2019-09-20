import os

from invoke import run, task

from . import copy
from . import requirements
from . import git_tasks


@task(requirements.install, git_tasks.clone_st2_repo, copy.copy_pack_to_subdirectory)
def packs_resource_register(ctx):
    print("")
    print("==================== packs-resource-register ====================")
    print("")
    base_branch = os.environ.get('BASE_BRANCH', 'origin/master')
    files = []
    top_level_git_dir = ctx.run('git rev-parse --show-toplevel').stdout.splitlines()[0]
    with ctx.cd(top_level_git_dir):
        files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                        "--name-only {}".format(base_branch)).stdout.splitlines()
    if files:
        ctx.run("st2-check-print-pack-tests-coverage {pack_dir}".format(pack_dir=top_level_git_dir))
    else:
        print("No files have changed, skipping run...")


@task(requirements.install)
def packs_tests(ctx):
    print("")
    print("==================== packs-tests ====================")
    print("")
    base_branch = os.environ.get('BASE_BRANCH', 'origin/master')
    files = []
    top_level_git_dir = ctx.run('git rev-parse --show-toplevel').stdout.splitlines()[0]
    with ctx.cd(top_level_git_dir):
        files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                        "--name-only {}".format(base_branch)).stdout.splitlines()
    if files:
        ctx.run("{st2_repo_path}/st2common/bin/st2-run-pack-tests -c -t -x -j -p "
                "{pack_dir}".format(
                    st2_repo_path=os.environ.get('ST2_REPO_PATH', '/tmp/st2'),
                    pack_dir=top_level_git_dir))
    else:
        print("No files have changed, skipping run...")


@task(requirements.install, git_tasks.clone_st2_repo)
def packs_missing_tests(ctx):
    print("")
    print("==================== pack-missing-tests ====================")
    print("")
    base_branch = os.environ.get('BASE_BRANCH', 'origin/master')
    files = []
    top_level_git_dir = ctx.run('git rev-parse --show-toplevel').stdout.splitlines()[0]
    with ctx.cd(top_level_git_dir):
        files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                        "--name-only {}".format(base_branch)).stdout.splitlines()
    if files:
        ctx.run("st2-check-print-pack-tests-coverage {pack_dir}".format(pack_dir=top_level_git_dir))
    else:
        print("No files have changed, skipping run...")
