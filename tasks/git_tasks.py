import os

from invoke import run, task


@task
def clone_st2_repo(recursive=False):
    if not os.path.exists('/tmp/st2'):
        try:
            from git import Repo
        except ImportError:
            run("git clone https://github.com/StackStorm/st2.git "
                "--depth 1 "
                "--single-branch "
                "--branch {st2_repo_branch} "
                "{st2_repo_path}".format(
                    st2_repo_path=os.environ.get('ST2_REPO_PATH'),
                    st2_repo_branch=os.environ.get('ST2_REPO_BRANCH')))
        else:
            Repo.clone_from(
                "https://github.com/StackStorm/st2.git",
                os.environ.get('ST2_REPO_PATH', '/tmp/st2'),
                depth=1,
                single_branch=True,
                branch=os.environ.get('ST2_REPO_BRANCH'))
