# Makefile.aws-ecs.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   really basic makefile workflows and usage patterns.  This file adds some
#   data/support function for coloring user output, primitives for doing
#   assertions on environment variables, stuff like that.
#
# REQUIRES: (system tools)
#   * jq
#
# DEPENDS: (other makefiles)
#   * Makefile.json.mk
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `placeholder`: placeholder description
#   PIPED TARGETS: (stdin->stdout)
#     * `ecs-list-services-json`:
#     * `ecs-get-deployments`:
#     * `ecs-get-services-string`:
#   MAKE-FUNCTIONS:
#     * `placeholder`: placeholder description
#
# VARS: (toplevel overrides, suggested additions for usage as Makefile include)
#   ECS_CLUSTER:=app-ecs-ECSCluster-IDNUM

# Retrieve and unpack service list JSON from ECS_CLUSTER
#
# Outputs JSON like:
# [ "arn:aws:ecs:REGION:ACCT:service/app-WorkerService1-ID",
#   ...
#   "arn:aws:ecs:REGION:ACCT:service/app-WorkerServiceN-ID", ]
#
 ecs-list-services-json: assert-ECS_CLUSTER
	$(call _announce_target, $@)
	@AWS_DEFAULT_REGION=${AWS_REGION} AWS_PROFILE=${AWS_PROFILE} aws \
	ecs list-services --cluster ${ECS_CLUSTER} \
	| jq ".serviceArns"


# example usage:
#
ecs-describe-task: assert-TASK_ARN
	@# placeholder
	$(call _announce_target, $@)
	@AWS_DEFAULT_REGION=${AWS_REGION} AWS_PROFILE=${AWS_PROFILE} \
	aws ecs describe-task-definition --task-definition $${TASK_ARN}

# example usage:
#
ecs-describe-services: assert-ECS_CLUSTER
	@# Retrieves service JSON from service ARN list
	$(call _announce_target, $@)
	$(eval SERVICE_ARN_LIST?=`make ecs-get-services-string`)
	@AWS_DEFAULT_REGION=${AWS_REGION} AWS_PROFILE=${AWS_PROFILE} aws \
	ecs describe-services --cluster ${ECS_CLUSTER} --services ${SERVICE_ARN_LIST}

# example usage:
#
ecs-get-services-string:
	@# Turn a JSON list [x,y,z] into a space-separated string like 'x y z'
	@make ecs-list-services-json | jq -r -c ".[]" | tr '\r\n' ' '

# example usage:
#
ecs-get-deployments:
	@# Unpack deployment information from service-json
	@make ecs-describe-services | jq -r ".services[].deployments"

# example usage:
#
ecs-task-definitions:
	@# give back a newline-separated string of task-definition ARNs
	$(call _announce_target, $@)
	@make ecs-get-deployments | jq -r -c ".[].taskDefinition"
ecs-get-tasks: ecs-task-definitions

# example usage:
#
ecs-task-map: assert-TARGET
	@# this is `map`from function programming, i.e. apply
	@# the given make target across each of the task ARNs
	$(call _announce_target, $@)
	make ecs-get-tasks | \
	while read TASK_ARN; do \
		TASK_ARN=$${TASK_ARN} make $${TARGET}; \
	done

# example usage:
#
ecs-describe-tasks:
	$(call _announce_target, $@)
	TARGET=ecs-describe-task make ecs-task-map

# example usage:
#
ecs-patch-task-definition: assert-TASK_ARN assert-TASK_IMAGE
	@# This patches the docker image used by $TASK_ARN without side effects,
	@# in other words returning patched JSON you can push from i.e.
	@# `ecs-post-task-revision`
	$(call _announce_target, $@)
	@make ecs-describe-task > tmp.json;
	@cat tmp.json|jq '.taskDefinition.containerDefinitions[].image|="$(value TASK_IMAGE)"'

# example usage:
#
ecs-service-update: assert-ECS_CLUSTER assert-ECS_SERVICE
	@# placeholder
	$(call _announce_target, $@)

# example usage:
#
ecs-post-task-revision: assert-TASK_ARN assert-TASK_IMAGE
	@# placeholder
	$(call _announce_target, $@)
	@# AWS API for describe-task-definition gives back more information
	@# than the API can handle for register-task-definition.  using $API_MAP
	@# we give the API back only the information it says it supports
	$(eval API_MAP:=.taskDefinition | {\
	family:.family, taskRoleArn: .taskRoleArn, \
	executionRoleArn: .executionRoleArn, \
	networkMode: .networkMode, \
	containerDefinitions: .containerDefinitions, \
	volumes: .volumes, \
	placementConstraints: .placementConstraints, \
	requiresCompatabilities: .requiresCompatibilities, \
	cpu: .cpu, memory: .memory})
	make ecs-patch-task-definition | jq "${API_MAP}" | \
	make json-filter-keys-with-null-value > update.json;
	AWS_DEFAULT_REGION=${AWS_REGION} AWS_PROFILE=${AWS_PROFILE} \
	aws ecs register-task-definition --cli-input-json file://update.json
