##
# Makefile.github.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   github workflows and usage patterns.
#
# REQUIRES: (system tools)
#   * git, ssh already setup for github
#
# DEPENDS: (other makefiles)
#   * Makefile.base.mk
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS:
#     - github-clone-org (vars: org=..., [cwd=..,] )
#   PIPED TARGETS: (stdin->stdout)
#     - None
#
#  $ make -f Makefile.base.mk -f Makefile.github.mk org=your-github-org
#
##
github-clone-org: assert-org
	@pushd $${cwd:-.} \
	; curl -s https://api.github.com/orgs/$$org/repos?per_page=200 \
	| jq -r '.[].clone_url' \
	| python3 -c '\
	import os, sys \
	; print("\n".join( \
		[ x.replace("https://github.com/", "git@github.com:") \
		  for x in sys.stdin.read().split()]))' \
	| xargs -I% bash -x -c 'ls `basename -s .git %` || git clone %' \
	&& ls $${cwd:-.}
