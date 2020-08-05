StackStorm Exchange CI
======================

Welcome to `ci`: the one repository that makes StackStorm Exchange tick. Indulge your natural
curiosity: take a look around and learn a little about how StackStorm Exchange works from the
inside!

This repository contains scripts for running tests and linters on pack PRs; sample files and
schemas; and finally, the index builder. If you're looking for lint configs that we use in
`flake8` and `pylint`, [the lint-configs repo](https://github.com/StackStorm/lint-configs)
would be the correct source.

The CI pipeline in StackStorm Exchange is based on CircleCI (see `.circle/circle.yml.sample`
for the reference config). On every PR we automatically run tests (if present), check the pack
config schemas, perform code style checks, and validate `pack.yaml`.

Once a PR is merged, the index update is run; StackStorm index is essentially a JSON file with
metadata and URLs for every pack we have.
See [the index repo](https://github.com/StackStorm-Exchange/index) for details, and while you
are at it, check out [the web front-end source code](https://github.com/StackStorm-Exchange/web)
as well.

If you wish to test a pack that uses the [pack.enable_common_libs](https://docs.stackstorm.com/reference/sharing_code_sensors_actions.html)
capability, then set the environment variable `COMMON_LIBS=true` in circleci or in your 
`.circleci/config.yml` file.

That's all folks!
