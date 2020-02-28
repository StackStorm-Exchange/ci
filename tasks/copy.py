import os
import shutil

from invoke import run, task


@task
def copy_pack_to_subdirectory(ctx):
    pack_name = os.environ['PACK_NAME']
    shutil.rmtree('/tmp/packs/{pack_name}'.format(pack_name=pack_name), ignore_errors=True)
    if not os.path.exists('/tmp/packs'):
        os.mkdir('/tmp/packs')
    shutil.copytree('.', '/tmp/packs/{pack_name}'.format(pack_name=pack_name))
