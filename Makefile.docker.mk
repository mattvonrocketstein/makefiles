# Makefile.docker.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   common workflows with docker and docker-compose, on local or remote hosts
#
# REQUIRES: (system tools)
#	  * docker-compose
#
# DEPENDS: (other makefiles and make-targets)
#   * makefiles/Makefile.ssh.mk
#   * toplevel `ssh` target
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `docker-remote-shell`:
#   PIPED TARGETS: (stdin->stdout)
#     * `vault-secret`: encrypt secret on stdin to stdout
#
# VARS: (toplevel overrides, suggested additions for usage as Makefile include)
#		ANSIBLE_ROOT = ${SRC_ROOT}/ansible
#		ANSIBLE_VAULT_PASSWORD_FILE := ${ANSIBLE_ROOT}/.vault_password
#

# target `docker-remote-shell`:
#   This target defers to the `ssh` target as far as setting up private keys,
#   usernames, and any other SSH options.
#
#   NB: We don't use `docker-compose exec` directly because of this issue:
#     https://github.com/docker/compose/issues/3352
#
# usage example: see main Makefile
#
docker-remote-shell: assert-SERVICE assert-COMPOSE_FILE assert-SERVICE_USER
	$(call _announce_target, $@)
	$(eval SERVICE_SHELL?="bash")
	$(eval DOCKER_PS_CMD=docker-compose -f $(value COMPOSE_FILE) ps -q $(value SERVICE))
	@# yep, need three \ to escape here
	SSH_CMD="docker exec -it -u $(value SERVICE_USER) \\\`${DOCKER_PS_CMD}\\\` $(value SERVICE_SHELL)" \
	make ssh-generic
