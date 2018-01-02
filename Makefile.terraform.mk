# Workflows for terraform.  This is most useful in that you can set/change your
# global `terraform` executable by overriding the makefile's ${TERRAFORM_EXEC}.
#
# Usage for this file as an include follow.
# Suggested variable-overrides in your toplevel Makefile:

TERRAFORM_EXEC ?= terraform

# A target to ensure fail-fast if terraform is not present
require-tf:
	${TERRAFORM_EXEC} --version &> /dev/null

# Target to extract a single value from terraform output.
# Output is quiet so it can be used directly with interpolation
#
# example usage (using output as argument):
#    ssh `var=host_ip make tf-get-output`
tf-get-output: assert-var
	$(call _announce_target, $@)
	@echo `${TERRAFORM_EXEC} output -json 2>/dev/null | jq -r .$$var.value`

# Target for simple proxy to terraform, "refresh" subcommand
tf-refresh:
	$(call _announce_target, $@)
	${TERRAFORM_EXEC} refresh

# A target that sets $TMP_TARGET (makefile) from $$target (bash)
# See `tf-plan` and `tf-apply` targets, which use this as a prereq
tf-set-tf-target:
	$(call _announce_target, $@)
	$(eval TMP_TARGET := $(shell bash -c '[ "$${target}" = "" ] && echo ""|| echo "-target=$${target}"'))
	@echo "set target: ${TMP_TARGET}"

# Target for simple proxy to terraform, "plan" subcommand.
#
# example usage (plan everything):
#    make tf-plan
#
# example usage (plan with target):
#    target=module.mymodule make tf-plan
tf-plan: tf-set-tf-target
	$(call _announce_target, $@)
	${TERRAFORM_EXEC} plan ${TMP_TARGET}

# Target for simple proxy to terraform, "apply" subcommand.
#
# example usage (apply everything):
#    make tf-apply
#
# example usage (apply with target):
#    target=module.mymodule make tf-apply
tf-apply: tf-set-tf-target
	$(call _announce_target, $@)
	${TERRAFORM_EXEC} apply

# Target for simple proxy to terraform, "get" subcommand.
tf-get:
	$(call _announce_target, $@)
	${TERRAFORM_EXEC} get

# Target for simple proxy to terraform, "get" subcommand.
tf-init:
	$(call _announce_target, $@)
	${TERRAFORM_EXEC} init

# Target for simple proxy to terraform, "output" subcommand, default to json out
# This version is quiet, and suitable for piping with i.e.
# `make tf-output|make json-to-yaml`
tf-output:
	@${TERRAFORM_EXEC} output -json

# Target for simple proxy to terraform, "taint" subcommand
tf-taint: tf-set-tf-target
	$(call _announce_target, $@)
	${TERRAFORM_EXEC} taint

# Target to create a png graph of terraform resources.
# Requires dot.  TODO: see what can be done here
# to make a graph that ISNT so huge it's worthless
tf-graph: require-dot
	$(call _announce_target, $@)
	${TERRAFORM_EXEC} graph | dot -Tpng > graph.png
