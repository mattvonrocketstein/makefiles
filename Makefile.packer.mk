##
# See the docs/packer.md file for more information and examples
##

# for build output file; this includes the ami id
PACKER_MANIFEST ?= manifest.json
# for rendering (commented) yaml to the JSON that packer requires
PACKER_CONFIG_YAML ?= packer/build_ami.yaml
PACKER_CONFIG_JSON ?= packer/build_ami.json
PACKER_CONFIG = ${PACKER_CONFIG_JSON}
export PACKER_CONFIG PACKER_MANIFEST

# packer hates yaml, but we sometimes use it anyway
# and then convert to json, just to have comments
packer-render: assert-PACKER_CONFIG_YAML assert-PACKER_CONFIG_JSON
	$(call _announce_target, $@)
	cat ${PACKER_CONFIG_YAML} | make yaml-to-json > ${PACKER_CONFIG_JSON}

# gets the AMI ID for the last build.
# stay quiet so this is suitable for pipes
packer-get-ami:
	@cat ${PACKER_MANIFEST} \
	| jq -r .builds[].artifact_id \
	| cut -d: -f2

# retrieves key from PACKER_KEY_SSM_PATH
packer-get-key:
	ls ${SRC_ROOT}/packer.pem \
	|| AWS_PROFILE=605-legacy AWS_DEFAULT_REGION=us-east-1 \
	aws ssm get-parameter --with-decryption \
	--name ${PACKER_KEY_SSM_PATH} \
	| jq -r .Parameter.Value \
	> ${SRC_ROOT}/packer.pem

packer-build: assert-PACKER_IMAGE assert-PACKER_CONFIG packer-get-key
	$(call _announce_target, $@)
	cat ${PACKER_CONFIG}
	echo
	docker run -i \
	-v `pwd`:/workspace \
	-v ~/.aws:/root/.aws \
	-w /workspace \
	${PACKER_IMAGE} build \
	-var repo=$$(basename -s .git `git config --get remote.origin.url`) \
	-var sha=`git rev-parse HEAD` \
	-var branch=`git name-rev HEAD|awk '{print $$NF}'` \
	-var packer_manifest_file=${PACKER_MANIFEST} \
	${PACKER_CONFIG} \
	| tee build.out
