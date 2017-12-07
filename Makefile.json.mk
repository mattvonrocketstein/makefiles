#
# Makefile.json.mk:
#   Various targets for transforming JSON and YAML with pipes
#

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

# usage example:
#  $ echo '{"a": "a", "b": null}' | make json-filter-keys-with-null-value
#  {"a": "a"}
json-filter-keys-with-null-value:
	@# placeholder
	$(call _announce_target, $@)
	@cat /dev/stdin | jq 'del(.[] | nulls)'
