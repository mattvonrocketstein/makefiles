##
# See the docs/sceptre.md file for more information and examples
##
sceptre-base: assert-sceptre_cmd
	$(call _announce_target, $@)
	sceptre --debug --dir ${SCEPTRE_ROOT} \
	$${sceptre_extra:-} $(value sceptre_cmd)

sceptre-launch-env: assert-env
	$(call _announce_target, $@)
	sceptre_cmd="launch-env $${env}" \
	make sceptre-base

sceptre-generate-template: assert-env assert-stack
	$(call _announce_target, $@)
	sceptre_cmd="generate-template $${env} $$stack" \
	make sceptre-base

sceptre-delete-stack: assert-env assert-stack
	$(call _announce_target, $@)
	sceptre_cmd="delete-stack $${env} $$stack" \
	make sceptre-base

sceptre-launch-stack: assert-env assert-stack
	$(call _announce_target, $@)
	sceptre_cmd="launch-stack $${env} $${stack}" \
	make sceptre-base

sceptre-create-change-set: assert-env assert-stack
	$(call _announce_target, $@)
	sceptre_cmd="create-change-set $${env} $${stack} $${env}-$${stack} " \
	make sceptre-base
sceptre-create-changeset: sceptre-create-change-set
scc: sceptre-create-changeset

sceptre-describe-change-set: assert-env assert-stack
	$(call _announce_target, $@)
	sceptre_cmd="describe-change-set $${env} $${stack} $${env}-$${stack} " \
	make sceptre-base
sceptre-describe-changeset: sceptre-describe-change-set


sceptre-describe-env: assert-env
	$(call _announce_target, $@)
	sceptre_cmd="$${sceptre_extra:-} describe-env $(value env)" \
	make sceptre-base

sceptre-describe-stack: assert-env assert-stack
	$(call _announce_target, $@)
	sceptre --dir ${SCEPTRE_ROOT} describe-stack-outputs $(value env) $(value stack)
	sceptre --dir ${SCEPTRE_ROOT} describe-stack-resources $(value env) $(value stack)

sceptre-describe-envs:
	$(call _announce_target, $@)
	@find ${SCEPTRE_ROOT}/config/* \
	-maxdepth 1 -type d -exec basename {} \; \
	| xargs -I {} sceptre --dir ${SCEPTRE_ROOT} describe-env {}
sceptre-describe: sceptre-describe-envs

sd: sceptre-describe
sdc: sceptre-describe-change-set
sde: sceptre-describe-env
sds: sceptre-describe-stack
sle: sceptre-launch-env
sls: sceptre-launch-stack
sgt: sceptre-generate-template
