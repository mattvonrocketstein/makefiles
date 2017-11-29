
# Function & target for implicit guards that assert environment variables.
# These are usually used by other targets to ensure that environment variables
# are set before starting.
#
# example usage (as target prereq):
#
# 		my-target: assert-USER assert HOST
#     	echo $${USER}@$${HOST}
#
define _assert_var
	@if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi
endef
assert-%:
	$(call _assert_var, $*)

#
#
#
require-%:
	echo "not implemented yet"

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
OK_STRING=$(COLOR_GREEN)[OK]$(NO_COLOR)
ERROR_STRING=$(ERROR_COLOR)[ERROR]$(NO_COLOR)
WARN_STRING=$(WARN_COLOR)[WARNING]$(NO_COLOR)
define _announce_target
	@printf "$(COLOR_GREEN)[target]:$(NO_COLOR) $@\n"
endef
