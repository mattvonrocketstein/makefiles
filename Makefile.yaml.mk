#
# Makefile.yaml.mk:
#   Various targets for transforming YAML with pipes
#
LIB_MAKEFILE = $(abspath $(lastword $(MAKEFILE_LIST)))
LIB_MAKEFILE := `python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${LIB_MAKEFILE}`
LIB_ROOT := $(shell dirname ${LIB_MAKEFILE})

include ${LIB_ROOT}/Makefile.base.mk

# example usage: (with pipes, from bash)
#   $ cat input.yaml | make yaml-to-json > output.json
yaml-to-json: assert-path
	$(call _announce_target, $@)
	@ls $$path >/dev/null && cat $$path | \
	python -c '\
	import sys, yaml, json; \
	json.dump(yaml.load(sys.stdin), sys.stdout, indent=2)'
