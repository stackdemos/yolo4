.DEFAULT_GOAL := deploy

NAMESPACE 	  		  ?= kubeflow
KUBECONTEXT   		  ?= set-me-please
BUCKET_KIND   		  ?= undefined
PLATFORM_STATE_FILE   ?= $(error PLATFORM_STATE_FILE varialbe has not been defined!)
PLATFORM_STATE_BUCKET ?= $(firstword $(subst /, ,$(PLATFORM_STATE_FILE:s3://%=%)))
PLATFORM_STATE_REGION ?= $(shell aws s3api get-bucket-location --bucket $(PLATFORM_STATE_BUCKET) | jq -r '.LocationConstraint//"us-east-1"')

APP_ELABORATE_FILE    ?= hub.elaborate
APP_STATE_FILE_LOCAL  ?= hub.state
APP_STATE_FILE        ?= $(error APP_STATE_FILE varialbe has not been defined!)
APP_STATE 			  ?= $(APP_STATE_FILE_LOCAL),$(APP_STATE_FILE)
WORKSPACE             := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
TEMPDIR 			  := $(WORKSPACE)/.tmp
HUB_YAML              := hub.yaml
SOURCECODE_REPO       := https://github.com/agilestacks/kubeflow-extensions.git
SORUCECODE_PATH       := applications/keras-seq2seq/

ifeq ($(GIT_USER_NAME),)
	GIT_USER_NAME  := SuperHub
endif
ifeq ($(GIT_USER_EMAIL),)
	GIT_USER_EMAIL := support@agilestacks.com
endif

hub 	:= hub -d --aws_region=$(PLATFORM_STATE_REGION) --aws_use_iam_role_credentials=false
kubectl := kubectl --context="$(KUBECONTEXT)" --namespace=$(NAMESPACE)

git := git -C "$(WORKSPACE)"
rsync := rsync -auvhtrzi --progress --ignore-existing

define add_remote
	- $(git) remote add -f -t master --no-tags "$(2)" "$(1)" \
	|| $(git) remote set-url "$(2)" "$(1)"
endef

define fetch_dir
	$(git) checkout -b upstream/$(2) $(1)/master
	$(git) subtree split -q --squash --prefix=$(3) --annotate="[$(2)] " --rejoin -b merging/$(2)
	$(git) checkout master
	test -d "$(WORKSPACE)/$(4)" \
	|| ($(git) subtree add --prefix=$(4) --squash "merging/$(2)"; \
	    $(git) branch -D "merging/$(2)")
endef

$(WORKSPACE) $(TEMPDIR):
	mkdir -p $@

init: $(WORKSPACE)
	$(git) init
	$(git) config user.name "$(GIT_USER_NAME)"
	$(git) config user.email "$(GIT_USER_EMAIL)"

first-commit: $(WORKSPACE) $(TEMPDIR)
	git -C "$(TEMPDIR)" init
	git -C "$(TEMPDIR)" remote add app $(SOURCECODE_REPO)
	git -C "$(TEMPDIR)" fetch -q --depth 1 app
	git -C "$(TEMPDIR)" checkout -q FETCH_HEAD
	@ touch $(TEMPDIR)/.cpignore
	$(rsync) --exclude-from $(TEMPDIR)/.cpignore $(TEMPDIR)/$(SORUCECODE_PATH) $(WORKSPACE)
	@ rm -rf $(TEMPDIR)
	$(git) add .
	test -z "$$($(git) status -uno --porcelain)" \
	|| $(git) commit -m "Initial commit"

gitrepo: init first-commit
	$(call add_remote,$(SOURCECODE_REPO),extensions)
	$(call fetch_dir,extensions,nbextensions,nbextensions,nbextensions)
	$(call fetch_dir,extensions,kernel,jupyter-kernels/tensorflow-ktext-seq2seq,components/kernel)

deploy:
	$(kubectl) apply -f templates/rbac.yaml
	$(kubectl) apply -f templates/notebook-keyring-$(BUCKET_KIND).yaml
	$(kubectl) apply -f templates/notebook-config.yaml
	$(kubectl) apply -f templates/git-secret.yaml
	$(kubectl) apply -f templates/bucket-pv-$(BUCKET_KIND).yaml
	$(kubectl) apply -f templates/notebook-pvc.yaml --wait
	$(kubectl) create -f templates/notebook.yaml \
	|| $(kubectl) replace -f templates/notebook.yaml --wait

undeploy:
	- $(kubectl) delete -f templates/notebook.yaml --wait
	- $(kubectl) delete -f templates/notebook-pvc.yaml --wait
	- $(kubectl) delete -f templates/bucket-pv-$(BUCKET_KIND).yaml --wait
	- $(kubectl) delete -f templates/notebook-config.yaml --wait
	- $(kubectl) delete -f templates/git-secret.yaml
	- $(kubectl) delete -f templates/notebook-keyring-$(BUCKET_KIND).yaml
	- $(kubectl) delete -f templates/rbac.yaml

$(APP_ELABORATE_FILE) elaborate:
	$(hub) elaborate $(HUB_YAML) managed.yaml -s $(PLATFORM_STATE_FILE) -o $(APP_ELABORATE_FILE)

install: $(APP_ELABORATE_FILE) gitrepo
	$(hub) deploy $(APP_ELABORATE_FILE) -s $(APP_STATE) -e WORKSPACE=$(WORKSPACE)

uninstall: $(APP_ELABORATE_FILE)
	$(hub) undeploy $(APP_ELABORATE_FILE) -s $(APP_STATE) -e WORKSPACE=$(WORKSPACE)

clean:
	rm -rf $(APP_ELABORATE_FILE) \
		   $(APP_STATE_FILE_LOCAL) \
		   $(TEMPDIR)

explain:
	$(hub) explain $(APP_ELABORATE_FILE) $(APP_STATE_FILE_LOCAL) --color -r | less
.PHONY: explain

.PHONY: deploy undeploy install uninstall clean elaborate
