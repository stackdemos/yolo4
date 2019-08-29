.DEFAULT_GOAL := deploy

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

KUBECTL_ARGS :=

ifneq (,$(DOCKER_EMAIL))
	KUBECTL_ARGS += --docker-email=$(DOCKER_EMAIL)
endif

namespace:
	- $(kubectl) create namespace $(NAMESPACE)
.PHONY: namespace

deploy: namespace
	- @ $(kubectl) create secret docker-registry $(COMPONENT_NAME) \
		--docker-server=$(DOCKER_HOST) \
		--docker-username=$(DOCKER_USERNAME) \
		--docker-password=$(DOCKER_PASSWORD) $(KUBECTL_ARGS)

undeploy:
	- $(kubectl) delete secret $(COMPONENT_NAME)
