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
#     * `ecs-deployments`:
#     * `ecs-list-services-string`:
#   MAKE-FUNCTIONS:
#     * `placeholder`: placeholder description
#
# VARS: (toplevel overrides, suggested additions for usage as Makefile include)
#   ECS_CLUSTER:=app-ecs-ECSCluster-IDNUM


ecr-login:
	$$(AWS_PROFILE=${AWS_PROFILE} aws \
	ecr get-login --no-include-email --region ${AWS_REGION})

ecr-create-repo: require-jq assert-ECR_PROJECT
	$(call _announce_target, $@)
	AWS_PROFILE=${AWS_PROFILE} AWS_DEFAULT_REGION=${AWS_REGION} \
	aws ecr describe-repositories | \
	jq '.repositories[].repositoryName | select(test ("$${ECR_PROJECT}"))' \
	> ecr-repos-filtered.json
	[[ -z "`cat ecr-repos-filtered.json`" ]] && \
	AWS_PROFILE=${AWS_PROFILE} AWS_DEFAULT_REGION=${AWS_REGION} \
	aws ecr create-repository --repository-name $${ECR_PROJECT} || \
	echo "repo already exists"

ecr-push: ecr-login assert-TAG assert-ECR_BASE assert-ECR_NAMESPACE
	$(call _announce_target, $@)
	docker tag $${TAG} $${ECR_BASE}/$${ECR_NAMESPACE}/$${TAG}
	docker push $${ECR_BASE}/$${ECR_NAMESPACE}/$${TAG}

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

#
ecs-list-services-string:
	@# Turn a JSON list [x,y,z] into a space-separated string like 'x y z'
	@make ecs-list-services-json | jq -r -c ".[]" | tr '\r\n' ' '

ecs-deployments:
	@# Unpack deployment information from service-json
	@make ecs-describe-services | jq -r ".services[].deployments"

ecs-describe-services:
	@# Retrieves service JSON from service ARN list
	$(call _announce_target, $@)
	$(eval ARN_LIST:=`make ecs-list-services-string`)
	@AWS_DEFAULT_REGION=${AWS_REGION} AWS_PROFILE=${AWS_PROFILE} aws \
	ecs describe-services --cluster ${ECS_CLUSTER} --services ${ARN_LIST}

ecs-task-definitions:
	@# give back a newline-separated string of task-definition ARNs
	$(call _announce_target, $@)
	@make ecs-deployments | jq -r -c ".[].taskDefinition"
ecs-get-tasks: ecs-task-definitions

ecs-task-map: assert-TARGET
	@# this is `map`from function programming, i.e. apply
	@# the given make target across each of the task ARNs
	$(call _announce_target, $@)
	make ecs-task-definitions | \
	while read TASK_ARN; do \
		TASK_ARN=$${TASK_ARN} make $${TARGET}; \
	done

ecs-describe-tasks:
	$(call _announce_target, $@)
	TARGET=ecs-describe-task make ecs-task-map

ecs-describe-task: assert-TASK_ARN
	@# placeholder
	$(call _announce_target, $@)
	@AWS_DEFAULT_REGION=${AWS_REGION} AWS_PROFILE=${AWS_PROFILE} \
	aws ecs describe-task-definition --task-definition $${TASK_ARN}

ecs-patch-task-definition: assert-TASK_ARN assert-TASK_IMAGE
	@# This patches the docker image used by $TASK_ARN without side effects,
	@# in other words returning patched JSON you can push from i.e.
	@# `ecs-post-task-revision`
	$(call _announce_target, $@)
	@make ecs-describe-task > tmp.json;
	@cat tmp.json|jq '.taskDefinition.containerDefinitions[].image|="$(value TASK_IMAGE)"'

ecs-service-update: assert-ECS_CLUSTER assert-ECS_SERVICE
	@# placeholder
	$(call _announce_target, $@)


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
