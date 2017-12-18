# Makefile.cloudformation.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   Cloudformation workflows and usage patterns.  This automation makes
#   extensive use of [iidy](https://github.com/unbounce/iidy)
#
# REQUIRES: (system tools)
#   * iidy, awscli
#
# DEPENDS: (other makefiles)
#   * Makefile.base.mk
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `placeholder`: placeholder description
#   PIPED TARGETS: (stdin->stdout)
#     * `placeholder`: placeholder description
#     * `placeholder`: placeholder description
#     * `placeholder`: placeholder description
#   MAKE-FUNCTIONS:
#     * `placeholder`: placeholder description

DEFAULT_CHANGE_SET_NAME := changeSetOut

# static-analysis: show usage of `ImportValue`
cf-describe-imports: require-ack assert-path
	ack "Fn::ImportValue" $$path

cf-validate: assert-path
	$(call _announce_target, $@)
	aws cloudformation validate-template --template-body=file://$$path

cf-exports:
	$(call _announce_target, $@)
	aws cloudformation list-exports

require-iidy:
	@iidy --version

##
# iidy-.* targets.
##
iidy-history: iidy-events

iidy-events: require-iidy assert-stack
	iidy watch-stack $${stack}

iidy-init: assert-argfile
	ls $(value argfile)
	$(eval STACK_ARGFILE := $(value argfile))
	$(eval STACK_NAME := $(shell cat ${STACK_ARGFILE}|shyaml get-value StackName))
	export STACK_ARGFILE STACK_NAME

iidy-cs: iidy-init
	iidy create-changeset ${STACK_ARGFILE} ${DEFAULT_CHANGE_SET_NAME}

iidy-create: iidy-init
	$(call _announce_target, $@)
	iidy create-stack ${STACK_ARGFILE}

iidy-update: iidy-init
	$(call _announce_target, $@)
	iidy update-stack ${STACK_ARGFILE}

iidy-delete: iidy-init require-shyaml
	$(call _announce_target, $@)
	stack=`cat ${STACK_ARGFILE}|shyaml get-value StackName` \
	make cf-delete-stack

iidy-cs-apply: iidy-init
	iidy exec-changeset ${STACK_ARGFILE} ${DEFAULT_CHANGE_SET_NAME}

iidy-list-stacks: require-iidy
	iidy list-stacks

iidy-describe-stack: require-iidy assert-stack
	iidy describe-stack $$stack

##
# cf-.* targets chaining to iidy for now for improved UX,
# unless there's a real reason to implement them with aws-cli
##

# Operations on change-sets
cf-cs: iidy-cs
cf-cs-apply: iidy-cs-apply
cf-cs-delete: iidy-init
	$(call _announce_target, $@)
	aws cloudformation delete-change-set \
	--change-set-name ${DEFAULT_CHANGE_SET_NAME} \
	--stack-name ${STACK_NAME} || echo "Could not delete changeset.. maybe does not exist"

# CRUD operations
cf-create: iidy-create
cf-update: iidy-update
cf-delete-stack: assert-stack
	aws cloudformation delete-stack --stack-name $(value stack)
cf-list-stacks: iidy-list-stacks
cf-describe-stack: iidy-describe-stack
