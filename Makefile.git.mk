# Makefile.git.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   git workflows and usage patterns.
#
# REQUIRES: (system tools)
#   * git
#
# DEPENDS: (other makefiles)
#   * none
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#   PIPED TARGETS: (stdin->stdout)
#
# VARS: (toplevel overrides, suggested additions for usage as Makefile include)

git-install-precommit: git-assert-no-changes

git-assert-no-changes:
	git diff-index --quiet HEAD -- || echo "There are uncommitted changes for git, stash or push to proceed" && exit 1

git-update-fork-from-upstream: git-assert-upstream
	@# placeholder
	$(call _announce_target, $@)
	git fetch upstream
	git checkout master
	git merge upstream/master
	git push
fork-update: git-update-fork-from-upstream

git-assert-upstream:
	git remote|grep upstream

# example usage:
#   UPSTREAM=https://github.com/ORIGINAL_OWNER/ORIGINAL_REPOSITORY.git make git-set-upstream
#   UPSTREAM=git@github.com:mattvonrocketstein/makefiles.git make git-set-upstream
git-set-upstream: assert-UPSTREAM
	@# placeholder
	$(call _announce_target, $@)
	git remote add upstream $$UPSTREAM
