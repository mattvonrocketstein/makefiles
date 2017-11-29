#
# Makefile.ansible.mk:
#
#   Includable make-targets for common ansible workflows.
#

# Override variables like this in the including Makefile to match your setup
ANSIBLE_ROOT = ${SRC_ROOT}/ansible
ANSIBLE_ROLES_PATH = ${ANSIBLE_ROOT}/roles
ANSIBLE_PRIVATE_KEY = ${ANSIBLE_ROOT}/key.pem
ANSIBLE_CONFIG = ${ANSIBLE_ROOT}/ansible.cfg
ANSIBLE_VAULT_PASSWORD_FILE := ${ANSIBLE_ROOT}/.vault_password
export ANSIBLE_ROOT ANSIBLE_CONFIG ANSIBLE_ROLES_PATH ANSIBLE_VAULT_PASSWORD_FILE

# A target to ensure fail-fast if ansible is not present
require-ansible:
	@ansible --version

# usage example:
#  $ host=foo playbook=bar/baz.yml make ansible-provision
ansible-provision-host-playbook: assert-host assert-playbook
	inventory="$$host," make ansible-provision-inventory-playbook

# usage example:
#  $ inventory=./inventory.yaml playbook=bar/baz.yml make ansible-provision-inventory-playbook
ansible-provision-inventory-playbook: assert-inventory assert-playbook
	ansible-playbook \
	 --user ${ANSIBLE_USER} \
	 --vault-password-file=${ANSIBLE_VAULT_PASSWORD_FILE} \
	 --private-key ${ANSIBLE_PRIVATE_KEY} \
	 --inventory $$inventory \
	 $$playbook

 # Aassumes desired playbook name is the same as hostname, and playbook is
 # available in toplevel ${ANSIBLE_ROOT}
 #
 # example:
 #   $ host=foo.bar make ansible-provision-host
 ansible-provision-host: assert-host
 	host=$$host playbook=${ANSIBLE_ROOT}/$${host}.yml \
	make ansible-provision-host-playbook
