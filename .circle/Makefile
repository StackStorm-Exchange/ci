ROOT_DIR ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
NUM_CHANGED_FILES := $(shell $(CI_DIR)/utils/git-changes files | wc -w)
NUM_CHANGED_PY := $(shell $(CI_DIR)/utils/git-changes py | wc -w)
NUM_CHANGED_YAML := $(shell $(CI_DIR)/utils/git-changes yaml | wc -w)
NUM_CHANGED_JSON := $(shell $(CI_DIR)/utils/git-changes json | wc -w)
CHANGED_DIRECTORIES := $(shell $(CI_DIR)/utils/git-changes directories)
VIRTUALENV_DIR ?= virtualenv
ST2_REPO_PATH ?= /tmp/st2
ST2_REPO_BRANCH ?= master
FORCE_CHECK_ALL_FILES ?= false
FORCE_CHECK_PACK ?= false

export ST2_REPO_PATH ROOT_DIR FORCE_CHECK_ALL_FILES FORCE_CHECK_PACK

# All components are prefixed by st2
COMPONENTS := $(wildcard /tmp/st2/st2*)
COMPONENTS_RUNNERS := $(wildcard /tmp/st2/contrib/runners/*)

.PHONY: all
all: requirements lint packs-resource-register packs-tests

.PHONY: all-ci
all-ci: compile .license-check .flake8 .pylint .copy-pack-to-subdirectory .configs-check .metadata-check .packs-resource-register .packs-tests

.PHONY: changed-files
changed-files:
	@echo "NUM_CHANGED_PY: $(NUM_CHANGED_PY)"
	@echo "NUM_CHANGED_JSON: $(NUM_CHANGED_JSON)"
	@echo "NUM_CHANGED_YAML: $(NUM_CHANGED_YAML)"
	@echo "NUM_CHANGED_FILES: $(NUM_CHANGED_FILES)"
	@echo "CHANGED_DIRECTORIES: $(CHANGED_DIRECTORIES)"

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

.PHONY: compile
compile:
	@echo "======================= compile ========================"
	@echo "------- Compile all .py files (syntax check test) ------"
	if python -c 'import compileall,re; compileall.compile_dir(".", rx=re.compile(r"/virtualenv|virtualenv-osx|virtualenv-py3|.tox|.git|.venv-st2devbox"), quiet=True)' | grep .; then exit 1; else exit 0; fi
	@echo
	@echo "All files compiled successfully"

.PHONY: .flake8
.flake8:
	@echo
	@echo "==================== flake8 ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ]; then \
		echo "Force flake8 checks on all files"; \
		find $(ROOT_DIR)/* -name "*.py" | while read py_file; do \
			flake8 --config=$(CI_DIR)/lint-configs/python/.flake8 $$py_file || exit 1; \
		done; \
	elif [ ${NUM_CHANGED_PY} -gt 0 ]; then \
		echo "Checking ${NUM_CHANGED_PY} Python files"; \
		$(CI_DIR)/utils/git-changes py >~/.git-changes-py; \
		while read -r file; do \
			if [ -n "$$file" ]; then \
				flake8 --config=$(CI_DIR)/lint-configs/python/.flake8 $$file || exit 1; \
			fi; \
		done < ~/.git-changes-py; \
		if [ -e ~/.git-changes-py ]; then rm ~/.git-changes-py; fi; \
	else \
		echo "No files have changed, skipping run..."; \
	fi;

.PHONY: .pylint
.pylint:
	@echo
	@echo "==================== pylint ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	if [ "${COMMON_LIBS}" = "true" ]; then \
		echo "Common libs PATH selected"; \
		export PYTHONPATH=/home/circleci/repo/lib:${PYTHONPATH}; \
	fi; \
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ] || [ ${NUM_CHANGED_PY} -gt 0 ]; then \
		REQUIREMENTS_DIR=$(CI_DIR)/.circle/ \
		CONFIG_DIR=$(CI_DIR)/lint-configs/ \
		st2-check-pylint-pack $(ROOT_DIR) || exit 1; \
	else \
		echo "No files have changed, skipping run..."; \
	fi;

.PHONY: .configs-check
.configs-check:
	@echo
	@echo "==================== configs-check ===================="
	@echo
	@# The number of changed files in the AWS pack exceeds the limits of Bash,
	@# leading to CI failures like this:
	@# https://circleci.com/gh/StackStorm-Exchange/stackstorm-aws/320
	@# Instead of passing the entire list into a Bash for loop, we convert the
	@# make variable to a Bash string, convert that to a Bash array, and then
	@# iterate through each element of the array
	. $(VIRTUALENV_DIR)/bin/activate; \
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ]; then \
		echo "Force checking all YAML files"; \
		find $(ROOT_DIR)/* -name "*.yaml" -o -name "*.yml" | while read yaml_file; do \
			st2-check-validate-yaml-file "$$yaml_file" || exit 1 ; \
		done; \
	elif [ ${NUM_CHANGED_YAML} -gt 0 ]; then \
		echo "Checking $(NUM_CHANGED_YAML) YAML files"; \
		$(CI_DIR)/utils/git-changes yaml >~/.git-changes-yaml; \
		while read -r file; do \
			if [ -n "$$file" ]; then \
				st2-check-validate-yaml-file $$file || exit 1 ; \
			fi; \
		done < ~/.git-changes-yaml; \
		if [ -e ~/.git-changes-yaml ]; then rm ~/.git-changes-yaml; fi; \
	else \
		echo "No files have changed, skipping run..."; \
	fi
	@#
	. $(VIRTUALENV_DIR)/bin/activate; \
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ]; then \
		echo "Force checking all JSON files"; \
		find $(ROOT_DIR)/* -name "*.json" | while read json_file; do \
			st2-check-validate-json-file "$$json_file" || exit 1 ; \
		done; \
	elif [ -n "${NUM_CHANGED_JSON}" ]; then \
		echo "Checking $(NUM_CHANGED_JSON) JSON files"; \
		$(CI_DIR)/utils/git-changes json >~/.git-changes-json; \
		while read -r file; do \
			if [ -n "$$file" ]; then \
				echo "file: $$file"; \
				st2-check-validate-json-file $$file || exit 1 ; \
			fi; \
		done < ~/.git-changes-json; \
		if [ -e ~/.git-changes-json ]; then rm ~/.git-changes-json; fi; \
	else \
		echo "No files have changed, skipping run..."; \
	fi
	@#
	@echo
	@echo "==================== example config check ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ] || [ ${NUM_CHANGED_FILES} -gt 0 ]; then \
		st2-check-validate-pack-example-config /tmp/packs/$(PACK_NAME) || exit 1; \
	else \
		echo "No files have changed, skipping run..."; \
	fi;

.PHONY: .metadata-check
.metadata-check:
	@echo
	@echo "==================== metadata-check ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ] || [ ${NUM_CHANGED_YAML} -gt 0 ]; then \
		st2-check-validate-pack-metadata-exists $(ROOT_DIR) || exit 1; \
	else \
		echo "No files have changed, skipping run..."; \
	fi;

.PHONY: .packs-resource-register
.packs-resource-register:
	@echo
	@echo "==================== packs-resource-register ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ] || [ ${NUM_CHANGED_FILES} -gt 0 ]; then \
		st2-check-register-pack-resources /tmp/packs/$(PACK_NAME) || exit 1; \
	else \
		echo "No files have changed, skipping run..."; \
	fi;

.PHONY: .packs-tests
.packs-tests:
	@echo
	@echo "==================== packs-tests ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ] || [ ${NUM_CHANGED_FILES} -gt 0 ]; then \
		$(ST2_REPO_PATH)/st2common/bin/st2-run-pack-tests -c -t -x -j -p $(ROOT_DIR) || exit 1; \
	else \
		echo "No files have changed, skipping run..."; \
	fi;

.PHONY: .packs-missing-tests
.packs-missing-tests:
	@echo
	@echo "==================== pack-missing-tests ===================="
	@echo
	if [ "$${FORCE_CHECK_ALL_FILES}" = "true" ] || [ ${NUM_CHANGED_FILES} -gt 0 ]; then \
		st2-check-print-pack-tests-coverage $(ROOT_DIR) || exit 1; \
	else \
		echo "No files have changed, skipping run..."; \
	fi;

# Target which veries repo root contains LICENSE file with ASF 2.0 content
# We allow the napalm_logs and netbox packs to have MIT licenses, since they
# adopted those licenses before this check was put in place, so they are
# effectively grandfathered in
# However, all other packs, including any new packs, are required to be
# licensed under the Apache 2.0 License
.PHONY: .license-check
.license-check:
	@echo
	@echo "==================== license-check ===================="
	@echo
	@if [ ${NUM_CHANGED_FILES} -eq 0 ] && [ "$${FORCE_CHECK_ALL_FILES}" = "false" ]; then \
		echo "No files have changed, skipping run..."; \
	else \
		if [ ! -f "$(ROOT_DIR)/LICENSE" ]; then \
			echo "Missing LICENSE file in $(ROOT_DIR)"; \
			exit 2;\
		fi;\
		if [ "$$(python -c 'import yaml; f = open("/home/circleci/repo/pack.yaml"); print(yaml.safe_load(f.read())["name"]); f.close();')" = "napalm_logs" ] || \
		   [ "$$(python -c 'import yaml; f = open("/home/circleci/repo/pack.yaml"); print(yaml.safe_load(f.read())["name"]); f.close();')" = "netbox" ]; then \
			cat $(ROOT_DIR)/LICENSE | grep -q "MIT License"  || (echo "LICENSE file doesn't contain MIT license text" ; exit 2); \
			cat $(ROOT_DIR)/LICENSE | grep -q "Copyright (c) 2017 John Anderson"  || (echo "LICENSE file doesn't include John Anderson's name" ; exit 2); \
			cat $(ROOT_DIR)/LICENSE | grep -q "Permission is hereby granted, free of charge, to any person obtaining a copy"  || (echo "LICENSE file doesn't contain MIT license text" ; exit 2); \
			echo "Pack is licensed under the MIT License -- :)"; \
		else \
			cat $(ROOT_DIR)/LICENSE | grep -q "Apache License"  || (echo "LICENSE file doesn't contain Apache 2.0 license text" ; exit 2); \
			cat $(ROOT_DIR)/LICENSE | grep -q "Version 2.0"  || (echo "LICENSE file doesn't contain Apache 2.0 license text" ; exit 2); \
			cat $(ROOT_DIR)/LICENSE | grep -q "www.apache.org/licenses/LICENSE-2.0"  || (echo "LICENSE file doesn't contain Apache 2.0 license text" ; exit 2); \
			echo "Pack is licensed under the Apache 2.0 License -- :)"; \
		fi; \
	fi

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
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --upgrade "pip==20.0.2"
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/.circle/requirements-dev.txt
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/.circle/requirements-pack-tests.txt

.PHONY: requirements-ci
requirements-ci:
	@echo
	@echo "==================== requirements-ci ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --upgrade "pip==20.0.2"
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/.circle/requirements-dev.txt
	. $(VIRTUALENV_DIR)/bin/activate && $(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/.circle/requirements-pack-tests.txt

.PHONY: virtualenv
virtualenv: $(VIRTUALENV_DIR)/bin/activate
$(VIRTUALENV_DIR)/bin/activate:
	@echo
	@echo "==================== virtualenv ===================="
	@echo
	test -d $(VIRTUALENV_DIR) || virtualenv --no-site-packages $(VIRTUALENV_DIR)
