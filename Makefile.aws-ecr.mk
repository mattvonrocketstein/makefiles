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


ecr-login: assert-AWS_REGION
	$(call _announce_target, $@)
	@# Careful, tricky escaping
	@$$(aws ecr get-login --no-include-email --region ${AWS_REGION})

# example usage:
ecr-create-repo: require-jq assert-ECR_PROJECT assert-AWS_REGION
	$(call _announce_target, $@)
	AWS_DEFAULT_REGION=${AWS_REGION} \
	aws ecr describe-repositories | \
	jq '.repositories[].repositoryName | select(test ("$${ECR_PROJECT}"))' \
	> ecr-repos-filtered.json
	[ -z "`cat ecr-repos-filtered.json`" ] && \
	AWS_DEFAULT_REGION=${AWS_REGION} \
	aws ecr create-repository --repository-name $${ECR_PROJECT} || \
	echo "repo already exists"
	rm ecr-repos-filtered.json

# Example usage:
#
#  ```
#  AWS_PROFILE=YOUR_PROFILE \
#  DOCKER_REGISTRY=registry.hub.docker.com/library \
#  DOCKER_IMAGE=alpine \
#  ECR_REPO=external/alpine ECR_BASE=YOUR_ECR_URL_NO_HTTP \
#  DOCKER_TAG=latest \
#  make -f Makefile.base.mk -f Makefile.aws-ecr.mk ecr-mirror
#  ```
#
ecr-mirror: ecr-login assert-DOCKER_TAG assert-DOCKER_IMAGE assert-DOCKER_REGISTRY assert-ECR_BASE assert-ECR_REPO
	$(call _announce_target, $@)
	docker pull $(value DOCKER_REGISTRY)/$(value DOCKER_IMAGE):$(value DOCKER_TAG)
	docker tag \
	$(value DOCKER_REGISTRY)/$(value DOCKER_IMAGE):$(value DOCKER_TAG) \
	$(value ECR_BASE)/$(value ECR_REPO):$(value DOCKER_TAG)
	ECR_PROJECT=$(value ECR_REPO) ${MAKE} ${MY_MAKEFLAGS} ecr-create-repo
	docker push $(value ECR_BASE)/$(value ECR_REPO):$(value DOCKER_TAG)

# example usage:
ecr-push: ecr-login assert-DOCKER_TAG assert-ECR_BASE assert-ECR_REPO
	$(call _announce_target, $@)
	$(eval DEST_TAG?=${DOCKER_TAG})
	docker tag $(value DOCKER_TAG) $(value ECR_BASE)/$(value ECR_REPO)/$(value DEST_TAG)
	docker push $(value ECR_BASE)/$(value ECR_REPO)/$(value DEST_TAG)
