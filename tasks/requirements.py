import glob
import os

from invoke import task, run

from . import git_tasks


@task
def runners(ctx):
    print("")
    print("================== install runners ====================")
    print("")
    for component in glob.glob("{}/contrib/runners/*".format(os.environ.get('ST2_REPO_PATH', '/tmp/st2'))):
        print("===========================================================")
        print("Installing runner: {component}".format(component=component))
        print("===========================================================")
        with ctx.cd(component):
            ctx.run("python setup.py develop")
    print("")
    print("================== register metrics drivers ======================")
    print("")

    with ctx.cd(os.path.join(os.environ.get('ST2_REPO_PATH', '/tmp/st2'), 'st2common')):
        ctx.run("python setup.py develop")


@task(git_tasks.clone_st2_repo, runners)
def install(ctx):
    print("")
    print("==================== requirements ====================")
    print("")
    ctx.run("pip install --upgrade \"pip>=9.0,<9.1\"")
    home = os.path.expanduser("~")
    ci_dir = os.path.join(home, 'ci')
    ctx.run("pip install --cache-dir {home}/.pip-cache -q "
            "-r {ci_dir}/.circle/requirements-dev.txt".format(home=home, ci_dir=ci_dir))
    ctx.run("pip install --cache-dir {home}/.pip-cache -q "
            "-r {ci_dir}/.circle/requirements-pack-tests.txt".format(home=home, ci_dir=ci_dir))
