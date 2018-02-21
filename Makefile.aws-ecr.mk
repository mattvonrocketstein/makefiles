# Makefile.aws-ecr.mk:
#
# DESCRIPTION:
#   A makefile suitable for stand-alone usage or as an include of
#   a parent makefile, smoothing various ECR workflows and usage patterns.
#
# REQUIRES: (system tools)
#   * docker
#
# DEPENDS: (other makefiles)
#   * Makefile.base.mk
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `ecr-create-repo`: create repo if it doesn't exist
#     * `ecr-login`: login helper, useful as pre-req for other make targets
#     * `ecr-push`: placeholder description
#

# example usage:
ecr-login: assert-AWS_PROFILE assert-AWS_REGION
	$(call _announce_target, $@)
	$$(AWS_PROFILE=${AWS_PROFILE} aws \
	ecr get-login --no-include-email --region ${AWS_REGION})

# example usage:
ecr-create-repo: require-jq assert-ECR_PROJECT assert-AWS_PROFILE assert-AWS_REGION
	$(call _announce_target, $@)
	AWS_PROFILE=${AWS_PROFILE} AWS_DEFAULT_REGION=${AWS_REGION} \
	aws ecr describe-repositories | \
	jq '.repositories[].repositoryName | select(test ("$${ECR_PROJECT}"))' \
	> ecr-repos-filtered.json
	[[ -z "`cat ecr-repos-filtered.json`" ]] && \
	AWS_PROFILE=${AWS_PROFILE} AWS_DEFAULT_REGION=${AWS_REGION} \
	aws ecr create-repository --repository-name $${ECR_PROJECT} || \
	echo "repo already exists"
	rm ecr-repos-filtered.json

# example usage:
ecr-mirror: assert-DOCKER_TAG assert-DOCKER_REGISTRY assert-DOCKER_REPO
	$(call _announce_target, $@)
	docker pull $${DOCKER_REGISTRY}/$${DOCKER_REPO}:$${DOCKER_TAG} \
	&& make ecr-push

# example usage:
ecr-push: ecr-login assert-TAG assert-ECR_BASE assert-ECR_NAMESPACE
	$(call _announce_target, $@)
	docker tag $${TAG} $${ECR_BASE}/$${ECR_NAMESPACE}/$${TAG}
	docker push $${ECR_BASE}/$${ECR_NAMESPACE}/$${TAG}
