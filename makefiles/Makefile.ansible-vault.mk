#
# Makefile.ansible-vault.mk:
#
#   Includable make-targets for lightweight crypto workflows in CM
#
#		For more info on ansible-vault, see also:
#      https://docs.ansible.com/ansible/2.4/vault.html
#

# Override for your setup
ANSIBLE_ROOT = ${SRC_ROOT}/ansible
ANSIBLE_VAULT_PASSWORD_FILE := ${ANSIBLE_ROOT}/.vault_password

# example: encrypt a file at a certain path
#     $ path=/far/bar/baz make encrypt-path
encrypt-path: assert-path
	ansible-vault encrypt \
		--vault-password-file=${ANSIBLE_VAULT_PASSWORD_FILE} $$path

# example: decrypt a file at a certain path
#     $ path=/far/bar/baz make decrypt-path
decrypt-path: assert-path
	ansible-vault decrypt \
	--vault-password-file=${ANSIBLE_VAULT_PASSWORD_FILE} $$path

# examples: encode secret and put it on a file, or in the clipboard
#   $ echo hunter2 | make secret > password.txt
#   $ echo hunter2 | make secret | pbcopy
secret:
	ansible-vault encrypt_string - \
	--vault-password-file ${ANSIBLE_VAULT_PASSWORD_FILE}
