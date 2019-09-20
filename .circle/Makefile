ROOT_DIR ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VIRTUALENV_DIR ?= virtualenv
ST2_REPO_PATH ?= /tmp/st2
ST2_REPO_BRANCH ?= master

export ST2_REPO_PATH ST2_REPO_BRANCH ROOT_DIR

virtualenv: $(VIRTUALENV_DIR)/bin/activate
$(VIRTUALENV_DIR)/bin/activate:
	@echo
	@echo "==================== virtualenv ===================="
	@echo
	test -d $(VIRTUALENV_DIR) || virtualenv --no-site-packages $(VIRTUALENV_DIR)

$(VIRTUALENV_DIR)/bin/invoke: $(VIRTUALENV_DIR)
	. $(VIRTUALENV_DIR)/bin/activate && pip install invoke

.PHONY: invoke
invoke: virtualenv $(VIRTUALENV_DIR)/bin/invoke
	$(VIRTUALENV_DIR)/bin/pip install invoke

# https://stackoverflow.com/a/33018558
# Workaround to support all previous make targets
# This default target simply passes all targets on to invoke
# We can't add invoke as a make dependency for the .DEFAULT target since the
# dependency will get overridden by whatever target is passed in
.DEFAULT:
	@# Manually make virtualenv target
	if [ ! -d $(VIRTUALENV_DIR) ]; then make virtualenv; fi
	@# Manually make invoke target
	if [ ! -e $(VIRTUALENV_DIR)/bin/invoke ]; then $(VIRTUALENV_DIR)/bin/pip install invoke; fi
	. $(VIRTUALENV_DIR)/bin/activate && invoke --search-root=$(CI_DIR) $@
	@#. $(VIRTUALENV_DIR)/bin/activate && echo $$PYTHONPATH
