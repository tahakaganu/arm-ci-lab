STACK ?= foundation
TF := terraform -chdir=$(STACK)
VARS := -var-file=../common.tfvars

init:
	$(TF) init -backend-config=../backend.hcl -backend-config="key=$(STACK)/terraform.tfstate"
plan:
	$(TF) plan $(VARS)
apply:
	$(TF) apply $(VARS)
destroy:
	$(TF) destroy $(VARS)
fmt:
	terraform fmt -recursive

.PHONY: init plan apply destroy fmt