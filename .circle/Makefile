ROOT_DIR ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
CHANGED_FILES := $(shell $(CI_DIR)/utils/git-changes files)
CHANGED_DIRECTORIES := $(shell $(CI_DIR)/utils/git-changes directories)
CHANGED_PY := $(shell ${CI_DIR}/utils/git-changes py)
CHANGED_YAML := $(shell $(CI_DIR)/utils/git-changes yaml)
CHANGED_JSON := $(shell $(CI_DIR)/utils/git-changes json)
VIRTUALENV_DIR ?= virtualenv
ST2_REPO_PATH ?= /tmp/st2
ST2_REPO_BRANCH ?= master
FORCE_CHECK_ALL_FILES =? false
FORCE_CHECK_PACK =? false

export ST2_REPO_PATH ROOT_DIR FORCE_CHECK_ALL_FILES FORCE_CHECK_PACK

# All components are prefixed by st2
COMPONENTS := $(wildcard /tmp/st2/st2*)
COMPONENTS_RUNNERS := $(wildcard /tmp/st2/contrib/runners/*)

.PHONY: all
all: requirements lint packs-resource-register packs-tests

.PHONY: all-ci
all-ci: .flake8 .pylint .copy-pack-to-subdirectory .configs-check .metadata-check .packs-resource-register .packs-tests

.PHONY: lint
lint: requirements flake8 pylint configs-check metadata-check

.PHONY: flake8
flake8: requirements .flake8

.PHONY: pylint
pylint: requirements .clone_st2_repo .pylint

.PHONY: configs-check
configs-check: requirements .clone_st2_repo .copy-pack-to-subdirectory .configs-check

.PHONY: metadata-check
metadata-check: requirements .metadata-check

# Task which copies pack to temporary sub-directory so we can use old-style check scripts which
# # require pack to be in a sub-directory
.PHONY: .copy-pack-to-subdirectory
.copy-pack-to-subdirectory:
	rm -rf /tmp/packs/$(PACK_NAME)
	mkdir -p /tmp/packs/$(PACK_NAME)
	cp -r ./* /tmp/packs/$(PACK_NAME)

.PHONY: packs-resource-register
packs-resource-register: requirements .clone_st2_repo .copy-pack-to-subdirectory .packs-resource-register

.PHONY: packs-missing-tests
packs-missing-tests: requirements .packs-missing-tests

.PHONY: packs-tests
packs-tests: requirements .clone_st2_repo .packs-tests

.PHONY: .flake8
.flake8:
	@echo
	@echo "==================== flake8 ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; if [ ! "${CHANGED_PY}" ]; then echo "No files have changed, skipping run..."; fi; for file in ${CHANGED_PY}; do if [ -n "$$file" ]; then flake8 --config=$(CI_DIR)/lint-configs/python/.flake8 $$file || exit 1; fi; done

.PHONY: .pylint
.pylint:
	@echo
	@echo "==================== pylint ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; if [ ! "${CHANGED_PY}" ]; then echo "No files have changed, skipping run..."; else (REQUIREMENTS_DIR=$(CI_DIR)/.circle/ CONFIG_DIR=$(CI_DIR)/lint-configs/ st2-check-pylint-pack $(ROOT_DIR) || exit 1); fi;

.PHONY: .configs-check
.configs-check:
	@echo
	@echo "==================== configs-check ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; if [ ! "${CHANGED_YAML}" ]; then echo "No files have changed, skipping run..."; fi; for file in $(CHANGED_YAML); do if [ -n "$$file" ]; then st2-check-validate-yaml-file $$file || exit 1 ; fi; done
	. $(VIRTUALENV_DIR)/bin/activate; if [ ! "${CHANGED_JSON}" ]; then echo "No files have changed, skipping run..."; fi; for file in $(CHANGED_JSON); do if [ -n "$$file" ]; then st2-check-validate-json-file $$file || exit 1 ; fi; done
	@echo
	@echo "==================== example config check ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; if [ ! "${CHANGED_FILES}" ]; then echo "No files have changed, skipping run..."; else st2-check-validate-pack-example-config /tmp/packs/$(PACK_NAME) || exit 1; fi;

.PHONY: .metadata-check
.metadata-check:
	@echo
	@echo "==================== metadata-check ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; if [ ! "${CHANGED_YAML}" ]; then echo "No files have changed, skipping run..."; else (st2-check-validate-pack-metadata-exists $(ROOT_DIR) || exit 1); fi;

.PHONY: .packs-resource-register
.packs-resource-register:
	@echo
	@echo "==================== packs-resource-register ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; if [ ! "${CHANGED_FILES}" ]; then echo "No files have changed, skipping run..."; else st2-check-register-pack-resources /tmp/packs/$(PACK_NAME) || exit 1; fi;

.PHONY: .packs-tests
.packs-tests:
	@echo
	@echo "==================== packs-tests ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; if [ ! "${CHANGED_FILES}" ]; then echo "No files have changed, skipping run..."; else ($(ST2_REPO_PATH)/st2common/bin/st2-run-pack-tests -c -t -x -p $(ROOT_DIR) || exit 1); fi;

.PHONY: .packs-missing-tests
.packs-missing-tests:
	@echo
	@echo "==================== pack-missing-tests ===================="
	@echo
	if [ ! "${CHANGED_FILES}" ]; then echo "No files have changed, skipping run..."; else (st2-check-print-pack-tests-coverage $(ROOT_DIR) || exit 1); fi;

.PHONY: .clone_st2_repo
.clone_st2_repo: /tmp/st2
/tmp/st2:
	@echo
	@echo "==================== cloning st2 repo ===================="
	@echo
	@rm -rf /tmp/st2
	@git clone https://github.com/StackStorm/st2.git --depth 1 --single-branch --branch $(ST2_REPO_BRANCH) /tmp/st2

.PHONY: .install-runners
.install-runners:
	@echo ""
	@echo "================== install runners ===================="
	@echo ""
	@for component in $(COMPONENTS_RUNNERS); do \
		echo "==========================================================="; \
		echo "Installing runner:" $$component; \
		echo "==========================================================="; \
        (. $(VIRTUALENV_DIR)/bin/activate; cd $$component; python setup.py develop); \
	done
	@echo ""
	@echo "================== register metrics drivers ======================"
	@echo ""

	# Install st2common to register metrics drivers
	(. $(VIRTUALENV_DIR)/bin/activate; cd $(ST2_REPO_PATH)/st2common; python setup.py develop)

.PHONY: requirements
requirements: virtualenv .clone_st2_repo .install-runners
	@echo
	@echo "==================== requirements ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --upgrade "pip>=9.0,<9.1"
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/.circle/requirements-dev.txt
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/.circle/requirements-pack-tests.txt

.PHONY: requirements-ci
requirements-ci:
	@echo
	@echo "==================== requirements-ci ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --upgrade "pip>=9.0,<9.1"
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/.circle/requirements-dev.txt
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/.circle/requirements-pack-tests.txt

.PHONY: virtualenv
virtualenv: $(VIRTUALENV_DIR)/bin/activate
$(VIRTUALENV_DIR)/bin/activate:
	@echo
	@echo "==================== virtualenv ===================="
	@echo
	test -d $(VIRTUALENV_DIR) || virtualenv --no-site-packages $(VIRTUALENV_DIR)
