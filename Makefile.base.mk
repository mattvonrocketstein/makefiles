# Makefile.base.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   really basic makefile workflows and usage patterns.  This file adds some
#   data/support function for coloring user output, primitives for doing
#   assertions on environment variables, stuff like that.
#
# REQUIRES: (system tools)
#   * nothing?  this file should be pure make
#
# DEPENDS: (other makefiles)
#   * nothing.  this is the base include
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `placeholder`: placeholder description
#   PIPED TARGETS: (stdin->stdout)
#     * `placeholder`: placeholder description
#   MAKE-FUNCTIONS:
#     * `placeholder`: placeholder description
#
# VARS: (toplevel overrides, suggested additions for usage as Makefile include)
#		PLACEHOLDER := ${SRC_ROOT}/.foobar
#		export ANSIBLE_VAULT_PASSWORD_FILE

define _announce_assert
	@printf "$(COLOR_YELLOW)[${1}]:$(NO_COLOR) (=$2)\n" 1>&2;
endef
define _log
	@printf "$(COLOR_YELLOW)[log]:$(NO_COLOR)${1}\n" 1>&2;
endef

# Function & target for implicit guards that assert environment variables.
# These are usually used by other targets to ensure that environment variables
# are set before starting.
#
# example usage: asserts as Makefile-target prereqs
#
# 		my-target: assert-USER assert HOST
#     	echo $${USER}@$${HOST}
#
define _assert_var
	@if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set" 1>&2; \
		exit 1; \
	fi
endef
assert-%:
	$(call _announce_assert, $@, ${${*}})
	$(call _assert_var, $*)

# example usage: requires bin in $PATH as a Makefile-target prereq
#
#    my-target: requires-foo_cmd
#      foo_cmd arg1,arg2
#
require-%:
	which $*

# boilerplate that causes `make help` and `make list` to
# publish all the make-target names to stdout.  this mostly
# works correctly even with usage of `include`
.PHONY: no_targets__ list
no_targets__:
list-helper:
	@sh -c "$(MAKE) -p no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | sort"
help:
	$(call _announce_target, $@)
	@make list-helper|grep -v Makefile|grep -v assert-.*
list: help

# Helpers and data for user output things
#
# usage example (announcing the name of the current target on entry):
#
#    my-target:
#    	  $(call _announce_target, $@)
#
NO_COLOR:=\x1b[0m
COLOR_GREEN=\x1b[32;01m
COLOR_OK=${COLOR_GREEN}
COLOR_RED=\x1b[31;01m
ERROR_COLOR=${COLOR_RED}
WARN_COLOR:=\x1b[33;01m
COLOR_YELLOW=${WARN_COLOR}
OK_STRING=$(COLOR_GREEN)[OK]$(NO_COLOR)
ERROR_STRING=$(ERROR_COLOR)[ERROR]$(NO_COLOR)
WARN_STRING=$(WARN_COLOR)[WARNING]$(NO_COLOR)
# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"
define _announce_target
	@printf "$(COLOR_GREEN)[target]:$(NO_COLOR) $@\n " 1>&2
endef

define _stage
	@printf "$(COLOR_YELLOW)[stage]:$(NO_COLOR) ${1}\n " 1>&2;
endef

# example:
define _fail
	@INDENTION="  " \
	printf "$(COLOR_RED)[FAIL]:$(NO_COLOR)\n$${INDENTION}${1}\n" 1>&2;
	exit 1
endef
fail:
	$(call _fail, $${MSG})
