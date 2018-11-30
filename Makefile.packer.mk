##
# See the docs/packer.md file for more information and examples
##

# for build output file; this includes the ami id
PACKER_MANIFEST ?= manifest.json
# for rendering (commented) yaml to the JSON that packer requires
PACKER_CONFIG_YAML ?= packer/build_ami.yaml
PACKER_CONFIG_JSON ?= packer/build_ami.json
PACKER_CONFIG = ${PACKER_CONFIG_JSON}
PACKER_KEY_FILE ?= packer.pem
export PACKER_CONFIG PACKER_KEY_FILE PACKER_CONFIG_YAML PACKER_CONFIG_JSON PACKER_MANIFEST

PACKER_REPO = $(shell basename -s .git `git config --get remote.origin.url`)
PACKER_AMI_NAME?= $(shell python -c "print '${PACKER_REPO}'.replace('ami-', '').replace('ami','')")
export PACKER_REPO PACKER_AMI_NAME

# packer hates yaml, but just to have comments
# we sometimes use it anyway and convert to json
packer-render: assert-PACKER_CONFIG_YAML assert-PACKER_CONFIG_JSON
	$(call _announce_target, $@)
	cat ${PACKER_CONFIG_YAML} | make yaml-to-json > ${PACKER_CONFIG_JSON}

# gets the AMI ID(s) for the last build(s).
# stay quiet so this is suitable for pipes
packer-get-ami:
	@make packer-get-amis | head -1

packer-clean:
	$(call _announce_target, $@)
	rm -f ${PACKER_MANIFEST} ${PACKER_CONFIG_JSON}

packer-get-amis:
	@cat ${PACKER_MANIFEST} \
	| jq -r .builds[].artifact_id \
	| cut -d: -f2

# retrieves key from PACKER_KEY_SSM_PATH
packer-get-key:
	ls ${SRC_ROOT}/$(value PACKER_KEY_FILE) \
	|| AWS_PROFILE=605-legacy AWS_DEFAULT_REGION=us-east-1 \
	aws ssm get-parameter --with-decryption \
	--name ${PACKER_KEY_SSM_PATH} \
	| jq -r .Parameter.Value \
	> ${SRC_ROOT}/$(value PACKER_KEY_FILE)
	chmod go-rwx ${SRC_ROOT}/$(value PACKER_KEY_FILE)

packer-build: assert-PACKER_IMAGE assert-PACKER_CONFIG packer-get-key
	$(call _announce_target, $@)
	cat ${PACKER_CONFIG} | jq \
	&& docker run -i \
	-v `pwd`:/workspace \
	-v ~/.aws:/root/.aws \
	-w /workspace \
	${PACKER_IMAGE} build \
	-var repo=$(value PACKER_REPO) \
	-var ami_name=$(value PACKER_AMI_NAME) \
	-var sha=`git rev-parse HEAD` \
	-var branch=`git name-rev HEAD|awk '{print $$NF}'` \
	-var packer_manifest_file=${PACKER_MANIFEST} \
	$${PACKER_EXTRA_ARGS:-} ${PACKER_CONFIG} \
	| tee build.out
