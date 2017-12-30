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

# A target to ensure fail-fast if ansible is not present
require-ansible:
	@ansible --version

ansible-roles:
	$(call _announce_target, $@)
	ansible-galaxy install -r $${path:-${ANSIBLE_ROOT}/requirements.yml}

ansible-provision: assert-host assert-playbook
	$(call _announce_target, $@)
	@# dump env vars for debugging
	$(call _show_env, "\(ANSIBLE\|VIRTUAL\)")
	@# show ansible information for debugging
	ansible --version
	@# run playbook against host
	host=$(value host) playbook=$(value playbook) \
	ansible-playbook \
	--user $(value ANSIBLE_USER) \
	--vault-password-file=$(value ANSIBLE_VAULT_PASSWORD_FILE) \
	--private-key $(value ANSIBLE_KEY) \
	--inventory $(value host), \
	-e @$(value ANSIBLE_VARS_SECRET) \
	-e @$(value ANSIBLE_VARS_TF) \
	-e @$(value ANSIBLE_VARS_JENKINS) \
	-e @$(value ANSIBLE_VARS_BASE) $(value extra_ansible_args) \
	${ANSIBLE_ROOT}/$(value playbook).yml
