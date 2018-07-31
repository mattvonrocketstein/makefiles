# Makefile.docker.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   common workflows with docker and docker-compose, on local or remote hosts
#
# REQUIRES: (system tools)
#	  * docker, docker-compose
#
# DEPENDS: (other makefiles and make-targets)
#   * Makefile.base.mk
#   * Makefile.ssh.mk (targets: ssh-generic)
#
# INTERFACE: (primary targets intended for export; see usage examples)
#
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `docker-remote-shell`:
#     * `docker-lint`:
#
#   PIPED TARGETS: (stdin->stdout)
#     * `placeholder`: placeholder
#

docker-lint:
	$(call _announce_target, $@)
	docker run --rm -i hadolint/hadolint < Dockerfile

docker-find-tag: assert-TAG
	$(call _announce_target, $@)
	docker images ${TAG} | grep -v 'IMAGE ID'

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
