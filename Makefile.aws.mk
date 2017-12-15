# Makefile.aws.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   basic AWS workflows and usage patterns.
#
# REQUIRES: (system tools)
#   * jq
#
# DEPENDS: (other makefiles)
#   * placeholder
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
#
# VARS: (toplevel overrides, suggested additions for usage as Makefile include)
#   PLACEHOLDER:=placeholder

aws-key-destroy: assert-path assert-key
	$(call _announce_target, $@)
	echo "keypath: $${path}"
	rm -f "$${path}"
	aws ec2 delete-key-pair --key-name $${key}

aws-key-create: require-jq assert-path assert-key
	$(call _announce_target, $@)
	if [ -f $${path} ]; then \
		MSG="key $${path} already exists on filesystem\n" \
		MSG="$${MSG} remove it if you really want to procede" \
		make fail; \
	fi
	aws ec2 create-key-pair --key-name $${key} | \
	jq -r '.KeyMaterial' > $${path}
