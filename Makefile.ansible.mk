#
# Makefile.ansible.mk:
#
#   Includable make-targets for common ansible workflows.
#

# Override to match your setup
ANSIBLE_ROOT = ${SRC_ROOT}/ansible
ANSIBLE_ROLES_PATH = ${ANSIBLE_ROOT}/roles
ANSIBLE_CONFIG = ${ANSIBLE_ROOT}/ansible.cfg
ANSIBLE_VAULT_PASSWORD_FILE := ${ANSIBLE_ROOT}/.vault_password
export ANSIBLE_ROOT ANSIBLE_CONFIG ANSIBLE_ROLES_PATH ANSIBLE_VAULT_PASSWORD_FILE

# A target to ensure fail-fast if ansible is not present
require-ansible:
	ansible --version &> /dev/null

# Target for provisioning just one ansible host.  Usage:
#  $ host=foo playbook=bar/baz.yml make ansible-provision
ansible-provision: assert-host assert-playbook
	ansible-playbook \
	 --user ubuntu \
	 --vault-password-file=${ANSIBLE_VAULT_PASSWORD_FILE} \
	 --private-key ${PRIVATE_KEY} \
	 --inventory $$host, \
	 $$playbook
