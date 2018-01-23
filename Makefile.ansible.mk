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
#
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `require-ansible`: fail-fast if ansible is not present in $PATH
#     * `ansible-requirements`: refresh ansible galaxy roles ${ANSIBLE_GALAXY_REQUIREMENTS}
#     * `ansible-clean`: remove file cruft (like .retry's)
#			* `ansible-inventory-get`: retrieve merged ansible host/group vars from CLI
#   PIPED TARGETS: (stdin->stdout)
#     * placeholder
#

ANSIBLE_GALAXY_REQUIREMENTS?=${ANSIBLE_ROOT}/galaxy-requirements.yml

require-ansible:
	@# A quiet target to ensure fail-fast if ansible is not present
	ansible --version &> /dev/null

ansible-inventory-get: assert-host assert-var
	$(call _announce_target, $@)
	@export TMP=`mktemp` && \
	ansible localhost \
	--connection local -i ${ANSIBLE_INVENTORY} \
	--module-name copy --args "\
	content={{hostvars['$$host']}} dest=$${TMP}" \
	> /dev/null && \
	cat $${TMP} | jq -r .$$var

ansible-graph: assert-host require-ansible-inventory-grapher
	$(call _announce_target, $@)
	ansible-inventory-grapher \
	-i ${ANSIBLE_INVENTORY} -q $$host | \
	dot -Tpng  > tmp.png
	open tmp.png

ansible-requirements:
	$(call _announce_target, $@)
	ansible-galaxy install -r ${ANSIBLE_GALAXY_REQUIREMENTS}

ansible-clean:
	find ${SRC_ROOT} -type f | \
	grep [.]retry$$ | \
	xargs rm

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

ansible-adhoc-group: assert-group require-ansible require-shyaml
	$(call _announce_target, $@)
	$(eval host:= $(shell group=$$group make ansible-get-group))
	ANSIBLE_USER=pi host=$(value host) \
	make ansible-adhoc-host

ansible-adhoc-host: assert-host
	$(call _announce_target, $@)
	ansible all -i $(value host), \
		--user=$(value ANSIBLE_USER) \
		--private-key=$(value ANSIBLE_PRIVATE_KEY) \
		-m $$module $$extra_ansible_args

ansible-adhoc:
	@# Run adhoc ansible against either a host
	@# or a group, using the rest of the current
	@# environment's settings for keys, users, etc
	$(call _announce_target, $@)
	@if [ "$$host" = "" ]; then \
		make ansible-adhoc-group; \
		exit $$?; \
	else \
		make ansible-adhoc-host; \
	fi

ansible-ping:
	@# Helper for verifying connectivity with ansible's ping.
	module=ping make ansible-adhoc
