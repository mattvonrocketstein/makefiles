# Makefile.rundeck.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, providing
#   a small, opinionated automation-API over a project-specific rundeck
#   instance (in other words this isn't intended for general deployments).
#   See https://github.com/elo-enterprises/rundeck/skeleton for more details
#
# REQUIRES: (system tools)
#   * python
#
# DEPENDS: (other automation)
#   * Makefiles.base.mk (user messages)
#   * scripts/rundeck/ (helper to negotiate tokens from user/password)
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `rundeck-ps`: chain to docker-compose for listing containers
#     * `rundeck-start`: chain to docker-compose for start
#     * `rundeck-restart`: chain to docker-compose for restart
#     * `rundeck-logs`: chain to docker-compose for logs
#     * `rundeck-terraform`: run the terraform provisioning against this rundeck
#     * `rundeck-ansible`: run the ansible provisioning against this rundeck
#   PARAMETRIC TARGETS: (su)
#     * `placeholder`
#   PIPED TARGETS: (stdin->stdout)
#     * `placeholder`
#
# VARIABLES: (preconditions and postconditions)
#   IMPORTS: (should be preset in a parent makefile or the env)
#			* `RUNDECK_SERVER_URL`: defaults to `http://localhost:4440`
#     * `RUNDECK_USER`: defaults to `admin`
#     * `RUNDECK_PASSWORD`: defaults to `admin`
#   EXPORTS: (values set by targets, intended for external reads)
#			* `PLACEHOLDER`: ..
##

_THIS_MAKEFILE = $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
THIS_MAKEFILE := $(lastword $(call _THIS_MAKEFILE))
RUNDECK_AUTOMATION_ROOT := $(shell echo `dirname ${THIS_MAKEFILE}`)

rundeck-dc-base: assert-cmd
	ls ${RUNDECK_CFILE} \
	&& cd rundeck \
	&& docker-compose -f ${RUNDECK_CFILE} $${cmd}

rundeck-ansible-playbook: assert-playbook
	$(call _announce_target, $@)
	cmd="\
	ls ${RUNDECK_ANSIBLE_FOLDER} \
	&& pushd ${RUNDECK_ANSIBLE_FOLDER} \
	&& ansible-playbook \
	-i localhost, \
	$${playbook}" make rundeck-ctx

rundeck-ansible:
	$(call _announce_target, $@)
	playbook=create-projects.yml make rundeck-ansible-playbook

rundeck-bootstrap:
	$(call _announce_target, $@)
	playbook=bootstrap.yml make rundeck-ansible-playbook
	ansible-playbook -i local, -e ansible_connection=local /tmp/bootstrap.yml

rundeck-terraform:
	$(call _announce_target, $@)
	set +x; cmd='\
	ls ${RUNDECK_TERRAFORM_FOLDER} \
	&& pushd ${RUNDECK_TERRAFORM_FOLDER} \
	&& export TF_VAR_RUNDECK_SERVER_URL=${RUNDECK_SERVER_URL} \
	&& export TF_VAR_RUNDECK_TOKEN=$${RUNDECK_TOKEN} \
	&& ${RUNDECK_TERRAFORM_BIN} init \
	&& ${RUNDECK_TERRAFORM_BIN} apply -auto-approve \
	' make rundeck-ctx

rundeck-auth-helper:
	$(call _announce_target, $@)
	@# chain to the auth-helper script
	@export auth_script=${RUNDECK_AUTOMATION_ROOT}/scripts/rundeck/auth-helper.py \
	&& python3 $${auth_script}

rundeck-ctx: assert-cmd
	$(call _announce_target, $@)
	echo "\
	`make rundeck-auth-helper` \
	&& $${cmd}" | bash

rundeck-provision:
	$(call _announce_target, $@)
	make rundeck-ansible
	make rundeck-terraform

rundeck-up:
	$(call _announce_target, $@)
	cmd="up -d" make rundeck-dc-base

rundeck-start:
	$(call _announce_target, $@)
	make rundeck-up
	ansible all -e ansible_connection=local \
	-i localhost, -m ansible.builtin.uri \
	-a "url=$${RUNDECK_SERVER_URL} method=GET status_code=200"

rundeck-restart:
	$(call _announce_target, $@)
	cmd=restart make rundeck-dc-base

rundeck-build:
	$(call _announce_target, $@)
	cmd="build" make rundeck-dc-base

rundeck-init: rundeck-build

rundeck-ps:
	$(call _announce_target, $@)
	cmd="ps" make rundeck-dc-base

rundeck-shell:
	$(call _announce_target, $@)
	cmd="exec rundeck bash" make rundeck-dc-base

rundeck-logs:
	$(call _announce_target, $@)
	cmd="logs -f" make rundeck-dc-base

rundeck-stop:
	$(call _announce_target, $@)
	cmd="down -t 1" make rundeck-dc-base
