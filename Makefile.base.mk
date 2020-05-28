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
# EXPORTS: (data available to other makefiles)
#   * MY_MAKEFLAGS: like builtin ${MAKEFLAGS}, but includes --makefile args
#
## INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `require-%`:for usage as pre-requisite target, with
#				the provided parameter.  this guard is used to assert
#       an executable exists in $PATH before entering another
#       target
#     * `assert-%`: for usage as pre-requisite target, with
#				the provided parameter.  this guard is used to assert
#       an environment variable before entering another target
#   PIPED TARGETS: (stdin->stdout)
#     * `placeholder`: placeholder description
#   MAKE-FUNCTIONS:
#     * `_show_env`: dump a subset of env-vars for easy debugging
#     * `_INFO`, `_DEBUG`,`_WARN`: standard loggers
#

SHELL := bash
MAKEFLAGS += --warn-undefined-variables --no-print-directory
.SHELLFLAGS := -euo pipefail -c

# ${MAKEFLAGS} is standard, but does not include --file arguments, see
# https://www.gnu.org/software/make/manual/html_node/Options_002fRecursion.html
# this is a constant annoyance whenever make targets want to invoke other make
# targets with the same environment.  an example value here is something like
# `-f Makefile.base.mk -f Makefile.ansible.mk`.  this macro is obnoxious, and
# it makes a strong assumption that only one make-target is given in the main
# CLI, but it's struggling to succinct and portable
MY_MAKEFLAGS:=$(shell \
	ps -p $${PPID} -o command | tail -1 \
	| xargs -n 1 | tail -n +2  | sed '$$d' | xargs)

define _INFO
	printf "$(COLOR_YELLOW)(`hostname`) [$@]:$(NO_COLOR) INFO $1\n" 1>&2;
endef
define _WARN
	printf "$(COLOR_RED)(`hostname`) [$@]:$(NO_COLOR) WARN $1\n" 1>&2;
endef
define _DEBUG
	printf "$(COLOR_RED)(`hostname`) [$@]:$(NO_COLOR) DEBUG $1\n" 1>&2;
endef

# `_show_env`: A make function for showing the contents of all environment
# variables.  This information goes to stderr so it can be safely used in
# make-targets that do stdin/stdout piping.  The argument to this function is
# passed as an argument for `grep`, thus filtering the output of the `env`.
#
#  example usage: (from a make-target, show only .*ANSIBLE.* vars in env)
#
#     target_name:
#      $(call _show_env, ANSIBLE)
#
#  example usage: (from a make-target, show .*ANSIBLE.* or .*VIRTUALENV.* vars)
#
#     target_name:
#				$(call _show_env, "\(ANSIBLE\|VIRTUAL\)")
#
define _show_env
	@printf "$(COLOR_YELLOW)(`hostname`) [<env filter=$1>]:$(NO_COLOR)\n" 1>&2;
	@env | grep $1 | sed 's/^/  /' 1>&2 || true
	@printf "$(COLOR_YELLOW)(`hostname`) [</env>]:$(NO_COLOR)\n"
endef

# Parametric makefile-target `assert-%`:
# Makefile-function `_assert_var`:
#
# Implicit guards that assert environment variables.  These are usually used by
# other targets as prerequisite targets to ensure that environment variables are
# set before starting.
#
# example usage: (for an existing make-target, set env-var prerequisites)
#
#		my-target: assert-USER assert-HOST
#   	echo $${USER}@$${HOST}
#
define _announce_assert
	export tmp=`echo '${1}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$$//'` \
	; printf "$(COLOR_YELLOW)(`hostname`)$(NO_COLOR) [$$tmp]:$(NO_COLOR) (=$2)\n" 1>&2;
endef
define _assert_var
	@if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* is not set" 1>&2; \
		exit 1; \
	fi
endef
define _assertnot_var
	@if [ "${${*}}" != "" ]; then \
		echo "Environment variable $* is set, and shouldn't be!" 1>&2; \
		exit 1; \
	fi
endef
assert-%:
	$(call _announce_assert, $@, ${${*}})
	$(call _assert_var, $*)
assertnot-%:
	$(call _assertnot_var, $*)

#
# example usage: (for existing make-target, declare command in $PATH as prereq)
#
#    my-target: requires-foo_cmd
#      foo_cmd arg1,arg2
#
require-%: ## bonk bonk
	@which $* > /dev/null

# Boilerplate and makefile-target `help` and `list`:
#
# This causes `make help` and `make list` to publish all the make-target names
# to stdout.  This is a hack, since make isn't exactly built to support reflection,
# but all the complexity here is inspection, string parsing, and still works
# (mostly) correctly even in case of usage of macros and make-includes.
#
# example usage: (from command line)
#
#   $ make help
#   [target]: help
#   ansible-provision
#	  ansible-provision-inventory-playbook
#   ..
#   ..
.PHONY: no_targets__ list
no_targets__:
_help-helper:
	@sh -c "\
	$(MAKE) -p no_targets__ | \
	awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);\
	for(i in A)print A[i]}' | grep -v '__\$$' | grep -v '\[' | sort"
help:
	$(call _announce_target, $@)
	@make _help-helper \
	| python3 -c "\
	from __future__ import print_function; \
	import os, re, sys, functools; \
	from collections import OrderedDict; \
	inp = sys.stdin.read(); \
	lines = inp.split('\n'); \
	ignored = 'Makefile list fail i in not if else for'.split(); \
	fstarts = 'assert range('.split(); \
	targets = [ x.strip() for i, x in enumerate(lines) if x.strip() not in ignored and not any([x.startswith(y) for y in fstarts]) ]; \
	inp2 = os.popen('make -p no_targets__'); \
	inp2_lines = inp2.readlines() ; \
	hints = [ [ line.strip(), '\n'.join(inp2_lines[i:i+6]) ] for i, line in enumerate(inp2_lines) if any([line.strip().startswith(t+':') for t in targets]) ]; \
	hints = [ [ t, block[block.find('recipe to execute (from '):].split('\n')[0] ] for t, block in hints]; \
	hints = [ [ t, block[block.find('(from ')+7:block.rfind(')')+2]] for t, block in hints ]; \
	hints = [ [ t, block.split(', ')[0][:-1] +' '+ block.split(', ')[-1][:-2]] for t, block in hints ]; \
	hints = [ dict(target=t.split(':')[0], args=t.split(':')[1:], file=block.strip().split() and block.split()[0], line=block.strip().split() and block.split(' line ')[-1]) for t, block in hints ]; \
	hints = [ dict(target=h['target'], args=[_.strip() for _ in h['args'] if _], file=(h['file'] and h['file'].replace(os.getcwd(), '.')) or None, line=h['line']) for h in hints ]; \
	hints = [ {k: v for d in [h, dict()] for k, v in d.items()} for h in hints]; \
	hints = [ dict(target=h['target'], file=h['file'], line=h['line'], \
		prereqs=[x for x in h['args'] if not x.startswith('assert-')], \
		args=functools.reduce(lambda x,y: x+y, [_.split() for _ in h['args']],[]),) \
		for h in hints ]; \
	hints = [ dict(target=h['target'], args=[x[len('assert-'):] for x in h['args'] if x.startswith('assert-')], file=h['file'], line=h['line']) for h in hints ]; \
	hints = [ {k: v for d in [h, {}] for k, v in d.items()} for h in hints]; \
	targets = sorted(hints, key=lambda _: _['target']); \
	targets = OrderedDict([[_['target'], _] for _ in targets]); \
	sources = [ [f, [h for h in hints if h['file']==f]] for f in set([x['file'] for x in hints]) if f ]; \
	sources = sorted(sources, key=lambda _: _[0]); \
	sources=OrderedDict(sources); \
	hdr = '\n$(COLOR_YELLOW)--- TARGETS BY SOURCE---$(NO_COLOR)\n\n  '; \
	print(hdr + '\n  '.join(['[$(COLOR_GREEN){}$(NO_COLOR)] ($(COLOR_CYAN){}$(NO_COLOR))'.format( \
		_, '..') for _, h in sources.items()])); \
	msg_t = '[$(COLOR_GREEN){target}$(NO_COLOR)]\n'; \
	msg_t+= '    source: $(COLOR_CYAN){source}$(NO_COLOR)\n'; \
	msg_t+= '  {args}'; \
	print(\
		'\n$(COLOR_YELLOW)--- ALL TARGETS ---$(NO_COLOR)\n\n  ' + \
		'\n  '.join(\
			[	msg_t.format( \
					target = h['target'], \
					source = ':'.join([h['file'], h['line']]) if (h['file'] and h['line']) else '?', \
					args = '  args: {}'.format(h['args']) if h['args'] else '' \
				) for _, h in targets.items() \
			]),\
	)"


# Helpers and data for user output things
#
# usage example (announcing the name of the current target on entry):
#
#    my-target:
#    	  $(call _announce_target, $@)
#
NO_COLOR:=\033[0m
COLOR_GREEN=\033[92m
COLOR_OK=${COLOR_GREEN}
COLOR_RED=\033[91m
COLOR_CYAN=\033[96m
COLOR_LBLUE=\033[94m
ERROR_COLOR=${COLOR_RED}
WARN_COLOR:=\033[93m
	WARN_COLOR:=\033[93m
COLOR_YELLOW=${WARN_COLOR}
OK_STRING=$(COLOR_GREEN)[OK]$(NO_COLOR)
ERROR_STRING=$(ERROR_COLOR)[ERROR]$(NO_COLOR)
WARN_STRING=$(WARN_COLOR)[WARNING]$(NO_COLOR)
# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"

define _announce_target
	@printf "$(COLOR_GREEN)(`hostname`)$(NO_COLOR)$(COLOR_CYAN) *$(abspath $(firstword $(MAKEFILE_LIST)))*$(NO_COLOR)\n   $(COLOR_LBLUE)[target]:$(NO_COLOR) $@\n" 1>&2
endef

define _stage
	@printf "$(COLOR_YELLOW)(`hostname`) [stage]:$(NO_COLOR) ${1}\n " 1>&2;
endef

# example:
define _fail
	@INDENTION="  "; \
	printf "$(COLOR_RED)(`hostname`) [FAIL]:$(NO_COLOR)\n$${INDENTION}${1}\n" 1>&2;
	exit 1
endef
fail:
	$(call _fail, $${MSG})
