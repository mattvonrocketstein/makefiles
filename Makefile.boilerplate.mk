##
# Project Makefile for $PROJECT_NAME
#  Project bootstrapping
#  Project automation entry points
#  Project command/control facilities
##
SHELL := bash
MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -euxo pipefail -c
.DEFAULT_GOAL := default

##
# Makefile project context and includes
##

# NOTE: `firstword` below gives top-level Makefile,
# whereas `lastword` gives the last included Makefile.
THIS_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))

# In case Makefile is a symlink, follow it before we compute
# ${SRC_ROOT}.  We use python because bash `readlink` breaks OSX
THIS_MAKEFILE := `python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${THIS_MAKEFILE}`

# Set root directories, everything else is based on them
SRC_ROOT := $(shell dirname ${THIS_MAKEFILE})
PROJECT_ROOT := ${SRC_ROOT}

##
# lib locations and includes:
# lib submodule should be added with:
#   `git submodule add git@github.com:user/makefiles.git .makefiles`
##
MAKE_INCLUDES_DIR := ${SRC_ROOT}/.makefiles
include ${MAKE_INCLUDES_DIR}/Makefile.base.mk
include ${MAKE_INCLUDES_DIR}/Makefile.yaml.mk
include ${MAKE_INCLUDES_DIR}/Makefile.json.mk
include ${MAKE_INCLUDES_DIR}/Makefile.ssh.mk
include ${MAKE_INCLUDES_DIR}/Makefile.python.mk
include ${MAKE_INCLUDES_DIR}/Makefile.ansible-vault.mk

# begin local includes
# include ${SRC_ROOT}/Makefile.placeholder.mk

##
# Makefile.ssh.mk:
#   example variables for ssh automation
##

# SSH_USER := ubuntu
# SSH_KEY := ~/.ssh/some.key
# SSH_HOST := example.com

##
# Makefile.ansible.mk and Makefile.ansible-vault.mk:
#   example variables for ansible automation
##

# ANSIBLE_USER := ${SSH_USER}
# ANSIBLE_ROOT ?= ${SRC_ROOT}/ansible
# ANSIBLE_PRIVATE_KEY:=${SSH_KEY}
# ANSIBLE_FACT_TREE=${SRC_ROOT}/.facts
# ANSIBLE_ROLES_PATH := ${ANSIBLE_ROOT}/roles
# ANSIBLE_VARS_BASE = ${ANSIBLE_ROOT}/vars.yml
# ANSIBLE_CONFIG := ${ANSIBLE_ROOT}/ansible.cfg
# ANSIBLE_INVENTORY = ${ANSIBLE_ROOT}/inventory.yml
# ANSIBLE_VAULT_FILES_PATTERN:=.*vault.*
# ANSIBLE_VAULT_PASSWORD_FILE := ${ANSIBLE_ROOT}/.vault_password
# ANSIBLE_GALAXY_REQUIREMENTS?=${ANSIBLE_ROOT}/galaxy-requirements.yml
# export ANSIBLE_USER ANSIBLE_CONFIG
# export ANSIBLE_ROLES_PATH ANSIBLE_VAULT_PASSWORD_FILE


# clean: ansible-clean python-clean
# requirements: python-requirements ansible-requirements


# Helpers for devs to SSH into the instance we're creating.
# This is only for inspection/debugging, it's not used directly
# in provisioning.
ssh: assert-host
	$(call _announce_target, $@)
	SSH_KEY=$(value SSH_KEY) \
	SSH_USER=$(value SSH_USER) \
	SSH_HOST=$$host \
	make ssh-generic

provision: assert-playbook require-ansible require-shyaml
	$(call _announce_target, $@)
	@if [ "$$host" = "" ]; then \
		make provision-group; \
		exit $$?; \
	else \
		make provision-host; \
	fi

provision-group: assert-group assert-playbook require-ansible require-shyaml
	$(call _announce_target, $@)
	$(eval host:= $(shell group=grid make ansible-get-group))
	ANSIBLE_USER=pi host=$(value host) make provision

provision-host: assert-host assert-playbook require-ansible require-shyaml
	$(call _announce_target, $@)
	ansible-playbook \
	--user=$(value ANSIBLE_USER) \
	--vault-password-file=$(value ANSIBLE_VAULT_PASSWORD_FILE) \
	--private-key=$(value ANSIBLE_PRIVATE_KEY) \
	 -e @${ANSIBLE_VARS_BASE} \
	 -i $(value host), $$extra_ansible_args \
	 ansible/$(value playbook).yml

ping: ansible-ping

status-refresh:
	$(call _announce_target, $@)
	module="setup" \
	extra_ansible_args="--tree ${ANSIBLE_FACT_TREE}" \
	make ansible-adhoc
	tree ${ANSIBLE_FACT_TREE}

status-clean:
	@find ${ANSIBLE_FACT_TREE}/* -type f | \
	xargs -n 1 -I {} bash -ex -c \
	'cat {}|jq . > tmp; mv tmp {}'

status:
	$(call _announce_target, $@)
	@find ${ANSIBLE_FACT_TREE}/* -type f | \
	xargs -n 1 -I {} bash -ex -c \
	'host=`basename {}` make status-host'

status-host: assert-host
	$(call _announce_target, $@)
	@cat ${ANSIBLE_FACT_TREE}/$$host | \
	jq ".ansible_facts | \
	.ansible_kernel,\
	.ansible_eth0.ipv4.address,\
	.ansible_wlan0.ipv4.address,\
	.ansible_lsb\
	"

status-query: require-jq assert-path assert-key
	$(call _announce_target, $@)
	ls ${ANSIBLE_FACT_TREE}/$$host | \
	xargs -n 1 -I {} bash -ex -c "cat {}|jq ''"

reboot:
	$(call _announce_target, $@)
	playbook=reboot make provision

# Special playbook to bootstrap host.  This will ask for
# user/password interactively and setup the ssh keys.
bootstrap: assert-host require-ansible require-shyaml
	ansible-playbook \
   --user=$(ANSIBLE_USER) \
	 -e @${ANSIBLE_VARS_BASE} \
	 -e lab_pub_key_path=${LAB_PUBKEY_PATH} \
	 --vault-password-file=${ANSIBLE_VAULT_PASSWORD_FILE} \
	 -i $$host, \
	 ansible/bootstrap.yml

 ## Begin special targets, operating against local instead of with remotes
 ###############################################################################

# Special playbook to install hosts mentioned in
# ansible/manifest.yml into localhost's /etc/hosts
local-hosts:
	extra_ansible_args="--ask-become-pass --connection=local" \
	make hosts
local-keys:
	host=localhost \
	extra_ansible_args="--ask-become-pass --connection=local" \
	playbook=key-up make

hosts: require-ansible
	@#
	$(call _announce_target, $@)
	ansible-playbook \
	 -i nil, \
	 --vault-password-file=${ANSIBLE_VAULT_PASSWORD_FILE} \
	 --private-key=${LAB_KEY_PATH} $$extra_ansible_args \
	 ansible/network-hosts.yml


dns:
	# Target to update DNS service (dnsmasq) on $LAB_DNS_HOST to
	# include all hosts and host aliases inside ansible/manifest.yml
	host=${LAB_DNS_HOST} playbook=dnsmasq make provision

cabot-reset:
	@ cabot_conf -c http://cabot.lan/ -u admin -p admin --factory_reset ansible/data/cabot.json

cabot-load:
	@ cabot_conf -c http://cabot.lan/ -u admin -p admin ansible/data/cabot.json
