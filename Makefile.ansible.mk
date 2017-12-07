# Makefile.ansible.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   ansible workflows and usage patterns.  For more info on ansible, see also:
#   https://docs.ansible.com
#
# REQUIRES: (system tools)
#   * ansible
#   * ansible-playbook
#
# DEPENDS: (other makefiles)
#   * placeholder
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `require-ansible`: fail-fast if ansible is not present
#     * `ansible-provision-inventory-playbook`
#   PIPED TARGETS: (stdin->stdout)
#     * placeholder
#
# VARS: (toplevel overrides, suggested additions for usage as Makefile include)
#		ANSIBLE_ROOT = ${SRC_ROOT}/ansible
#		ANSIBLE_ROOT = ${SRC_ROOT}/ansible
#		ANSIBLE_ROLES_PATH = ${ANSIBLE_ROOT}/roles
#		ANSIBLE_PRIVATE_KEY = ${ANSIBLE_ROOT}/key.pem
#		ANSIBLE_CONFIG = ${ANSIBLE_ROOT}/ansible.cfg
#		ANSIBLE_VAULT_PASSWORD_FILE := ${ANSIBLE_ROOT}/.vault_password
#		export ANSIBLE_ROOT ANSIBLE_PRIVATE_KEY ANSIBLE_CONFIG ANSIBLE_ROLES_PATH ANSIBLE_VAULT_PASSWORD_FILE

# A target to ensure fail-fast if ansible is not present
require-ansible:
	@ansible --version

# example usage:
#  $ inventory=./inventory.yaml playbook=bar/baz.yml make ansible-provision-inventory-playbook
ansible-provision-inventory-playbook: assert-inventory assert-playbook
	$(call _announce_target, $@)
	ansible-playbook --user=$(value ANSIBLE_USER) \
	--vault-password-file=$(value ANSIBLE_VAULT_PASSWORD_FILE) \
	--private-key $(value ANSIBLE_PRIVATE_KEY) \
	--inventory $(value inventory) $(value playbook)

ansible-roles:
	$(call _announce_target, $@)
	ansible-galaxy install -r $${path:-${ANSIBLE_ROOT}/requirements.yml}

# A target for average use-case where playbook is specified but inventory is
# determined by a single host argument
#
# example usage:
#  $ inventory=./inventory.yaml playbook=bar/baz.yml make ansible-provision
ansible-provision: assert-playbook assert-host
	$(call _announce_target, $@)
	playbook=$${playbook} inventory="$${host}," make ansible-provision-inventory-playbook
