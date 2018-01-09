#
# Makefile.yaml.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   Cloudformation workflows and usage patterns.  This automation makes
#   extensive use of [iidy](https://github.com/unbounce/iidy)
#
# REQUIRES: (system tools)
#   * j2, python
#
# DEPENDS: (other makefiles)
#   * Makefile.base.mk
#

# Render templated YAML with YAML context vars
yaml-render: assert-context assert-path assert-output require-j2
	$(call _announce_target, $@)
	@j2 -f yaml $${path} $${context} > $${output}

yaml-concat: assert-input assert-output
	if [ -e "$$output" ]; then \
		rm $$output; \
	fi
	if [ -d "$$input" ]; then \
		find $$input/*.yml -type f | \
		xargs -I {} bash -ex -c 'cat {} | tee -a $$output'; \
	fi

# example usage: (invoked via shell, with pipes)
#   $ cat input.yaml | make yaml-to-json > output.json
yaml-to-json:
	$(call _announce_target, $@)
	@python -c '\
	import sys, yaml, json; \
	json.dump(yaml.load(sys.stdin), sys.stdout, indent=2)'

# example usage: (invoked via shell, with pipes)
#   $ cat my.yaml | make yaml-validate
yaml-validate: assert-path
	$(call _announce_target, $@)
	@python -c 'import sys, yaml; yaml.load(sys.stdin)'

yaml-validate-dir:
