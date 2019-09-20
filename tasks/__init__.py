from invoke import Collection, task, run

from . import check
from . import copy
from . import git_tasks
from . import lint
from . import requirements
from . import tests


# All tasks are implemented in submodules of this package
# All tasks in this module are only for reverse compatibility with the original
# Makefile

# This task aliases a Python built-in
@task(requirements.install, lint.lint, tests.packs_resource_register, tests.packs_tests)
def all_(ctx):
    pass


@task(check.compile_, lint.flake8, lint.pylint, copy.copy_pack_to_subdirectory,
      check.configs, check.metadata, tests.packs_resource_register, tests.packs_tests)
def all_ci(ctx):
    pass


@task(lint.lint)
def lint_(ctx):
    pass


@task(lint.flake8)
def flake8(ctx):
    pass


@task(lint.pylint)
def pylint(ctx):
    pass


@task(check.configs)
def configs_check(ctx):
    pass


@task(check.metadata)
def metadata_check(ctx):
    pass


@task(tests.packs_resource_register)
def packs_resource_register(ctx):
    pass


@task(tests.packs_missing_tests)
def packs_missing_tests(ctx):
    pass


@task(tests.packs_tests)
def packs_tests(ctx):
    pass


@task(check.compile_)
def compile_(ctx):
    pass


@task(requirements.runners)
def install_runners(ctx):
    pass


@task(requirements.install)
def requirements(ctx):
    pass


namespace = Collection()

namespace.add_task(all_, name='all')
namespace.add_task(all_ci, name='all-ci')
namespace.add_task(lint_, name='lint')
namespace.add_task(flake8, name='flake8')
namespace.add_task(pylint, name='pylint')
namespace.add_task(configs_check, name='configs-check')
namespace.add_task(metadata_check, name='metadata-check')
namespace.add_task(packs_resource_register, name='packs-resource-register')
namespace.add_task(packs_missing_tests, name='packs-missing-tests')
namespace.add_task(packs_tests, name='packs-tests')
namespace.add_task(compile_, name='compile')
namespace.add_task(install_runners, name='install-runners')
namespace.add_task(requirements, name='requirements')
