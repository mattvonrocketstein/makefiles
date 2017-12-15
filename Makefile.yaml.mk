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
yaml-render: assert-context assert-path require-j2
	$(call _announce_target, $@)
	@j2 -f yaml $$path $$context

# example usage: (with pipes, from bash)
#   $ cat input.yaml | make yaml-to-json > output.json
yaml-to-json:
	$(call _announce_target, $@)
	@python -c '\
	import sys, yaml, json; \
	json.dump(yaml.load(sys.stdin), sys.stdout, indent=2)'
