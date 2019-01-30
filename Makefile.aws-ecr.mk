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


ecr-login: assert-ECR_REGION assert-ECR_REGISTRY
	$(call _announce_target, $@)
	@# Careful, tricky escaping
	$(eval LOGIN_CMD = "aws ecr get-login --no-include-email --region $(value ECR_REGION) --registry-ids $(value ECR_REGISTRY)")
	@echo 'executing: ${LOGIN_CMD}'
	@$$(eval ${LOGIN_CMD})

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
	ECR_PROJECT=$(value ECR_REPO) ${MAKE} ${MY_MAKEFLAGS} ecr-create-repo
	${MAKE} ${MY_MAKEFLAGS} ecr-mirror-do

ecr-mirror-do: assert-DOCKER_TAG assert-DOCKER_IMAGE assert-DOCKER_REGISTRY assert-ECR_BASE assert-ECR_REPO
	$(call _announce_target, $@)
	docker pull $(value DOCKER_REGISTRY)/$(value DOCKER_IMAGE):$(value DOCKER_TAG)
	docker tag \
	$(value DOCKER_REGISTRY)/$(value DOCKER_IMAGE):$(value DOCKER_TAG) \
	$(value ECR_BASE)/$(value ECR_REPO):$(value DOCKER_TAG)
	docker push $(value ECR_BASE)/$(value ECR_REPO):$(value DOCKER_TAG)

# example usage:
ecr-push: ecr-login assert-DOCKER_TAG assert-ECR_BASE assert-ECR_REPO
	$(call _announce_target, $@)
	$(eval DEST_TAG?=${DOCKER_TAG})
	docker tag ${DOCKER_TAG} ${ECR_BASE}/${ECR_REPO}/${DEST_TAG}
	docker push ${ECR_BASE}/${ECR_REPO}/${DEST_TAG}

# example
# make ecr-mirror-all-x-account \
# ECR_REPO_FILTER=605data \
# SRC_AWS_REGION=us-east-1 SRC_ECR_BASE=248783370565.dkr.ecr.us-east-1.amazonaws.com SRC_AWS_PROFILE=605-legacy \
# DST_AWS_REGION=us-east-2 DST_ECR_BASE=873326152210.dkr.ecr.us-east-2.amazonaws.com DST_AWS_PROFILE=605-management
ecr-mirror-all-x-account: require-jq assert-ECR_REPO_FILTER assert-SRC_AWS_REGION assert-SRC_ECR_BASE assert-SRC_AWS_PROFILE assert-DST_AWS_REGION assert-DST_ECR_BASE assert-DST_AWS_PROFILE
	@$$(aws ecr get-login --no-include-email --region ${SRC_AWS_REGION} --profile ${SRC_AWS_PROFILE})
	@$$(aws ecr get-login --no-include-email --region ${DST_AWS_REGION} --profile ${DST_AWS_PROFILE})
	aws ecr describe-repositories --region ${SRC_AWS_REGION} --profile ${SRC_AWS_PROFILE} | \
	jq -r ".repositories[].repositoryName" | \
	grep "${ECR_REPO_FILTER}" \
	> .tmp.ecr-repos
	xargs -0 -I '{}' -n 1 ${MAKE} ecr-mirror-x-account ${MAKEFLAGS} ECR_REPO='{}' < <(tr \\n \\0 <.tmp.ecr-repos)
	rm .tmp.ecr-repos

# example
# make ecr-mirror-x-account \
# ECR_REPO=605data/chatops \
# SRC_AWS_REGION=us-east-1 SRC_ECR_BASE=248783370565.dkr.ecr.us-east-1.amazonaws.com SRC_AWS_PROFILE=605-legacy \
# DST_AWS_REGION=us-east-2 DST_ECR_BASE=873326152210.dkr.ecr.us-east-2.amazonaws.com DST_AWS_PROFILE=605-management
ecr-mirror-x-account: require-jq assert-ECR_REPO assert-SRC_AWS_REGION assert-SRC_ECR_BASE assert-SRC_AWS_PROFILE assert-DST_AWS_REGION assert-DST_ECR_BASE assert-DST_AWS_PROFILE
	$(call _announce_target, $@)
	@$$(aws ecr get-login --no-include-email --region ${SRC_AWS_REGION} --profile ${SRC_AWS_PROFILE})
	@$$(aws ecr get-login --no-include-email --region ${DST_AWS_REGION} --profile ${DST_AWS_PROFILE})
	aws ecr describe-images --region ${SRC_AWS_REGION} --profile ${SRC_AWS_PROFILE} --repository-name ${ECR_REPO} | \
	jq -r '.imageDetails[].imageTags[]?' \
	> .tmp.ecr-image-tags
	AWS_REGION=$(value DST_AWS_REGION) AWS_PROFILE=$(value DST_AWS_PROFILE) ECR_PROJECT=$(value ECR_REPO) ${MAKE} ecr-create-repo
	DOCKER_IMAGE=$(value ECR_REPO) \
	DOCKER_REGISTRY=$(value SRC_ECR_BASE) ECR_BASE=$(value DST_ECR_BASE) \
	xargs -0 -I '{}' -n 1 ${MAKE} ecr-mirror-do DOCKER_TAG='{}' < <(tr \\n \\0 <.tmp.ecr-image-tags)
	rm .tmp.ecr-image-tags
