.DEFAULT_GOAL := deploy

export HUB_CONFIG := $(realpath .)/.hubconfig
export HUB_PROTOCOL ?= https

ORG ?= please-define-hub-parameter
REPO ?= mysuperapp
PRIVATE ?= true
DESCRIPTION ?=
HOMEPAGE ?=
API_SERVER ?= api.github.com
SRC_DIR ?= $(realpath .)
REMOTE_NAME ?= $(ORG)-$(REPO)
GITHUB_FILE := .$(ORG)$(REPO).json

# We must cover case with empty value in variable
ifeq ($(USER_NAME),)
	USER_NAME := SuperHub
endif
ifeq ($(USER_NAME),)
	USER_EMAIL := support@agilestacks.com
endif

export GITHUB_TOKEN ?=
ifeq ($(GITHUB_TOKEN),)
	curl := curl -fs
else
	curl := curl -fs -H 'Authorization: token $(GITHUB_TOKEN)'
endif
jq := jq -cM
git := ghub -C $(SRC_DIR)

ifeq ($(GITHUB_TOKEN),)
	unexport GITHUB_TOKEN
endif
ifeq ($(PRIVATE),true)
	CREATE_ARGS += -p
endif
ifneq ($(DESCRIPTION),)
	CREATE_ARGS += -d "$(DESCRIPTION)"
endif
ifneq ($(HOMEPAGE),)
	CREATE_ARGS += -h "$(HOMEPAGE)"
endif

check-github-api:
	echo "Connecting to $(API_SERVER)... "
	- $(eval org=$(shell $(curl) -I https://$(API_SERVER)/orgs/$(ORG)))
	- $(eval user=$(shell $(curl) -I https://$(API_SERVER)/users/$(ORG)))

	$(if $(or $(org),$(user)),$(info "Connected"),$(error "Error connecting to $(API_SERVER)"))
PHONY: check-github-api

deploy: create push output

init:
	$(git) init
.PHONY: init

create: init check-github-api
	- $(git) create $(CREATE_ARGS) $(ORG)/$(REPO)
.PHONY: create

$(HUB_CONFIG):
	touch $@

undeploy: $(HUB_CONFIG)
	- echo yes | $(git) delete $(ORG)/$(REPO)
	rm -rf $(realpath $(SRC_DIR))/.git
.PHONY: undeploy

push:
	$(eval REMOTE=$(shell $(curl) https://$(API_SERVER)/repos/$(ORG)/$(REPO) | $(jq) '.clone_url'))
	@ echo Pushing to remote: $(REMOTE)

ifneq ($(GITHUB_TOKEN),)
	$(eval REMOTE=$(subst ://,://x-oauth-basic:$(GITHUB_TOKEN)@,$(REMOTE)))
endif
	- @ $(git) remote add $(REMOTE_NAME) "$(REMOTE)"
	- @ $(git) remote set-url $(REMOTE_NAME) "$(REMOTE)"
	$(git) fetch --tags --progress $(REMOTE_NAME)
	- $(git) add .gitignore
	$(git) add -A
	$(git) config user.name "$(USER_NAME)"
	$(git) config user.email "$(USER_EMAIL)"
	-$(git) commit -am "Initial commit"
	$(git) checkout --ours .
	-$(git) push $(REMOTE_NAME) master
.PHONY: clone

$(GITHUB_FILE):
	@ $(curl) https://$(API_SERVER)/repos/$(ORG)/$(REPO) > $@

output: $(GITHUB_FILE)
	$(eval clone_url := $(shell $(jq) '.clone_url' < $<))
	$(eval git_url := $(shell $(jq) '.git_url' < $<))
	$(eval html_url := $(shell $(jq) '.html_url' < $<))
	$(eval ssh_url := $(shell $(jq) '.ssh_url' < $<))
	$(eval private := $(shell $(jq) '.private' < $<))

	-@ echo
	-@ echo Outputs:
	-@ echo clone_url = $(clone_url)
	-@ echo git_url = $(git_url)
	-@ echo html_url = $(html_url)
	-@ echo ssh_url = $(ssh_url)
	-@ echo private = $(private)
	-@ echo
.PHONY: output

