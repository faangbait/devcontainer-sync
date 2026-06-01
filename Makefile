ANSIBLE_PLAYBOOK ?= ansible-playbook
PLAYBOOK ?= playbook.yml
WORKSPACE_ROOT ?=
EXAMPLE_VARS ?= group_vars/all.example.yml
TEST_WORKSPACE_ROOT ?= $(CURDIR)/tests

ifdef WORKSPACE_ROOT
ANSIBLE_ENV := WORKSPACE_ROOT=$(WORKSPACE_ROOT)
endif

.PHONY: help check apply create-missing syntax test

help:
	@printf "Targets:\n"
	@printf "  make check           Preview changes with --check --diff\n"
	@printf "  make apply           Apply rendered devcontainer files\n"
	@printf "  make create-missing  Create missing .devcontainer directories/files\n"
	@printf "  make syntax          Run Ansible syntax check\n"
	@printf "  make test            Render group_vars/all.example.yml into tests/\n"
	@printf "\nOverride workspace root with WORKSPACE_ROOT=/path/to/workspaces.\n"

check:
	$(ANSIBLE_ENV) $(ANSIBLE_PLAYBOOK) --check --diff $(PLAYBOOK)

apply:
	$(ANSIBLE_ENV) $(ANSIBLE_PLAYBOOK) --diff $(PLAYBOOK)

create-missing:
	$(ANSIBLE_ENV) $(ANSIBLE_PLAYBOOK) --diff $(PLAYBOOK) -e devcontainer_sync_create_missing=true

syntax:
	$(ANSIBLE_ENV) $(ANSIBLE_PLAYBOOK) --syntax-check $(PLAYBOOK)


test:
	$(ANSIBLE_PLAYBOOK) --diff $(PLAYBOOK) -e @$(EXAMPLE_VARS) -e workspace_root=$(TEST_WORKSPACE_ROOT) -e devcontainer_sync_create_missing=true -e devcontainer_sync_backup=false
	find $(TEST_WORKSPACE_ROOT) -type f ! -path $(TEST_WORKSPACE_ROOT)/golden_output -print0 | sort -z | xargs -0r cat > $(TEST_WORKSPACE_ROOT)/golden_output
