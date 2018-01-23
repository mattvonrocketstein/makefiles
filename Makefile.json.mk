#
# Makefile.json.mk:
#   Various targets for transforming JSON and YAML with pipes
#

# LIB_MAKEFILE = $(abspath $(lastword $(MAKEFILE_LIST)))
# LIB_MAKEFILE := `python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${LIB_MAKEFILE}`
# LIB_ROOT := $(shell dirname ${LIB_MAKEFILE})
#
# include ${LIB_ROOT}/Makefile.base.mk

# iterated render: use jinja to render json
# with itself until steady state is reached
define ITERATED_RENDER
import os, json, jinja2
ENV = jinja2.Environment()
MAX_PASSES = 5
last_t = open(os.environ['path']).read()
steady=False
for i in range(MAX_PASSES):
    r = json.loads(last_t)
    next_t = ENV.from_string(last_t).render(**r)
    if next_t == last_t:
        steady=True
        break
    last_t = next_t
if not steady: raise SystemExit('nested too deep')
else: print last_t
endef
export ITERATED_RENDER
json-irender: assert-path
	$(call _announce_target, $@)
	@echo "$${ITERATED_RENDER}"|python

# Render templated JSON values with JSON context vars
json-render: assert-context assert-path
	j2 -f json $$path $$context

json-validate: assert-path
	$(call _announce_target, $@)
	@cat $$path | \
	python -m json.tool >> \
	/dev/null && exit 0 || \
	echo "NOT valid JSON"; exit 1

# A prereq target to ensure fail-fast if jq is not present
require-jq:
	@jq --version &> /dev/null

# Target for use with pipes.  This performs fairly naive
# JSON-to-yaml conversion, using `default_flow_style` to
# opt for verbose output (avoids inlining of data).
#
# example:
#   $ terraform output -json | make json-to-yaml
json-to-yaml:
	@python -c 'import sys, json, yaml; print yaml.safe_dump(json.loads(sys.stdin.read()), default_flow_style=False)'


# Target for use with pipes.  This installs a simple wrapper around the
# piped-in JSON data, then encapsulates it under a single key given by $wrapper
#
# example usage:
#   $ terraform output -json | wrapper=terraform make json-wrap
json-wrapper:
	@make assert-wrapper > /dev/null
	@python -c "import os, sys, json; print json.dumps({ os.environ['wrapper']: json.loads(sys.stdin.read())})"

# Target for use with pipes.
#
# usage example:
#  $ echo '{"a": "a", "b": null}' | make json-filter-keys-with-null-value
#  {"a": "a"}
json-filter-keys-with-null-value:
	$(call _announce_target, $@)
	@cat /dev/stdin | jq 'del(.[] | nulls)'
