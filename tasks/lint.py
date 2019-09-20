import glob
import os

from invoke import task, run

from . import check
from . import git_tasks
from . import requirements


CI_DIR = os.environ.get('CI_DIR', '/home/circleci/ci')


@task(requirements.install)
def flake8(ctx):
    print("")
    print("==================== flake8 ====================")
    print("")
    top_level_git_dir = ctx.run('git rev-parse --show-toplevel').stdout.splitlines()[0]
    base_branch = os.environ.get('BASE_BRANCH', 'origin/master')
    files = []
    with ctx.cd(top_level_git_dir):
        files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                        "--name-only {} -- '*.py'".format(base_branch)).stdout.splitlines()
    if os.environ.get('FORCE_CHECK_ALL_FILES', False) == 'true':
        for file_ in glob.glob("**.py", recursive=True):
            ctx.run("flake8 --config={flake8_config} {flake8_file}".format(
                flake8_config=os.path.join(CI_DIR, 'lint-configs', 'python', '.flake8'),
                flake8_file=file_))
    elif files:
        for file_ in files:
            ctx.run("flake8 --config={flake8_config} {flake8_file}".format(
                flake8_config=os.path.join(CI_DIR, 'lint-configs', 'python', '.flake8'),
                flake8_file=file_))
    else:
        print("No files have changed, skipping run...")


@task(requirements.install, git_tasks.clone_st2_repo)
def pylint(ctx):
    print("")
    print("==================== pylint ====================")
    print("")
    top_level_git_dir = ctx.run('git rev-parse --show-toplevel').stdout.splitlines()[0]
    base_branch = os.environ.get('BASE_BRANCH', 'origin/master')
    files = []
    with ctx.cd(top_level_git_dir):
        files = ctx.run("git diff --relative --diff-filter=ACMRTUXB "
                        "--name-only {} -- '*.py'".format(base_branch)).stdout.splitlines()
    if os.environ.get('FORCE_CHECK_ALL_FILES', False) == 'true' or files:
        ctx.run('st2-check-pylint-pack {pack_dir}'.format(pack_dir=top_level_git_dir), env={
            'REQUIREMENTS_DIR': os.path.join(CI_DIR, '.circle'),
            'CONFIG_DIR': os.path.join(CI_DIR, 'lint-configs'),
        })
    else:
        print("No files have changed, skipping run...")


@task(requirements.install, flake8, pylint, check.configs, check.metadata)
def lint(ctx):
    pass
