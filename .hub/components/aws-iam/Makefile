.DEFAULT_GOAL    := deploy
COMPONENT_NAME   ?= app-role

STATE_BUCKET     ?= $(error STATE_BUCKET has been undefined)
STATE_REGION     ?= $(error STATE_REGION has been undefined)
DOMAIN_NAME      ?= $(error DOMAIN_NAME has been undefined)
APPLICATION_NAME ?= $(error APPLICATION_NAME has been undefined)

export AWS_DEFAULT_REGION ?= us-east-2
export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(APPLICATION_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

terraform   ?= terraform-v0.12
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

deploy: init plan apply

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/app/$(APPLICATION_NAME)/iam/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

output:
	@$(terraform) output -no-color

undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

clean:
	rm -rf .terraform

-include ../Mk/phonies
