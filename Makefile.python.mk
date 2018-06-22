# Makefile.python.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   python workflows and usage patterns.
#
# REQUIRES: (system tools)
#   * python
#
# DEPENDS: (other makefiles)
#   * Makefiles.base.mk
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `python-requirements`: pip install for ${SRC_ROOT}/requirements.txt
#   PIPED TARGETS: (stdin->stdout)
#     * placeholder
#

python-requirements:
	pip install -r ${SRC_ROOT}/requirements.txt

python-normalize: assert-src
	find $$src -type f \
	| grep .py$ \
	| xargs autopep8 --in-place

python-static-analysis: assert-src
	$(call _announce_target, $@)
	find $$src -type f \
	| grep .py$ \
	| xargs flake8
