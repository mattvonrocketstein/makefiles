##
# See the docs/sceptre.md file for more information and examples
##

sceptre-base: assert-sceptre_cmd
	$(call _announce_target, $@)
	sceptre --dir ${SCEPTRE_ROOT} \
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
sccs: sceptre-create-changeset

sceptre-delete-change-set: assert-env assert-stack
	$(call _announce_target, $@)
	sceptre_cmd="delete-change-set $${env} $${stack} $${env}-$${stack} " \
	make sceptre-base
sceptre-delete-changeset: sceptre-delete-change-set
sdc: sceptre-delete-changeset
sdcs: sceptre-delete-changeset

sceptre-execute-change-set: assert-env assert-stack
	$(call _announce_target, $@)
	sceptre_cmd="execute-change-set $${env} $${stack} $${env}-$${stack} " \
	make sceptre-base
sceptre-exec-change-set: sceptre-execute-change-set
sceptre-exec-changeset: sceptre-execute-change-set

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
	sceptre_cmd="describe-stack-outputs $(value env) $(value stack)" \
	make sceptre-base
	sceptre_cmd="describe-stack-resources $(value env) $(value stack)" \
	make sceptre-base

sceptre-describe-envs:
	$(call _announce_target, $@)
	@find ${SCEPTRE_ROOT}/config/* \
	-maxdepth 1 -type d -exec basename {} \; \
	| xargs -I {} sceptre --dir ${SCEPTRE_ROOT} describe-env {}
sceptre-describe: sceptre-describe-envs

# pulls an individual named export from a given stack
# staty quiet here, we need to remain pipe safe.
sceptre-pull-export: assert-env assert-stack assert-name
	@sceptre --dir ${SCEPTRE_ROOT} \
	describe-stack-outputs $(value env) $(value stack) \
	| make yaml-to-json \
	| jq -r '.[]|select(.OutputKey=="$(value name)").OutputValue'


sd: sceptre-describe
sdc: sceptre-describe-change-set
sde: sceptre-describe-env
sds: sceptre-describe-stack
sle: sceptre-launch-env
sls: sceptre-launch-stack
sgt: sceptre-generate-template
