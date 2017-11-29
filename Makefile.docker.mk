# target: `service-shell`
# depends: `ssh`
#
# Helps with a common work flow where you connect to remote host via SSH,
# then immediately want a shell inside the running container named $SERVICE
#
# This target depends on a more generic `ssh` target that should already exist
# and respect the `SSH_CMD` environment variable (See the example Makefile).
# This target defers to the `ssh` target as far as setting up private keys,
# usernames, and any other SSH options.
#
# We don't use `docker-compose exec` directly because of this issue:
#   https://github.com/docker/compose/issues/3352
#
# usage example: see main Makefile
#
service-shell: assert-SERVICE assert-COMPOSE_FILE assert-SERVICE_USER
	$(call _announce_target, $@)
	SSH_CMD="docker exec -it -u $$SERVICE_USER \`docker-compose -f $$COMPOSE_FILE ps -q $$SERVICE\` $${SERVICE_SHELL:-bash}" \
	make ssh
