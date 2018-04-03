# Makefile.git-bfg.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile,
#   smoothing various workflows with the BFG tool.
#   See also: https://rtyley.github.io/bfg-repo-cleaner/
#
# REQUIRES: (system tools)
#   * java
#
# DEPENDS: (other makefiles)
#   * Makefile.base.mk (base for asserts/display helpers)
#
# INTERFACE: (primary targets intended for export; see usage examples)
#
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `make bfg-require`: download/install bfg if not present
#     * `make bfg-clean-big-files`: clean large files
#
# VARS: (these can be overridden from toplevel Makefile if necessary)

BFG_JAR_FILE ?= ~/bin/bfg.jar
BFG_DOWNLOAD_URL := http://repo1.maven.org/maven2/com/madgag/bfg/1.13.0/bfg-1.13.0.jar

bfg-require:
	$(call _announce_target, $@)
	ls `dirname ${BFG_JAR_FILE}` \
	|| mkdir `dirname ${BFG_JAR_FILE}`
	wget -O ${BFG_JAR_FILE} ${BFG_DOWNLOAD_URL}
require-bfg: bfg-require

bfg-base: assert-BFG_CMD
	$(call _announce_target, $@)
	java -jar ${BFG_JAR_FILE} $${BFG_CMD}

bfg-clean-big-files: assert-MAX_SIZE
	$(call _announce_target, $@)
	BFG_CMD="--strip-blobs-bigger-than $${MAX_SIZE}M" \
	make bfg-base
