##
# See the docs/packer.md file for more information and examples
##

# for build output file; this includes the ami id
PACKER_MANIFEST ?= manifest.json
# for rendering (commented) yaml to the JSON that packer requires
PACKER_CONFIG_YAML ?= packer.yaml
PACKER_CONFIG_JSON ?= packer.json
PACKER_CONFIG = ${PACKER_CONFIG_JSON}
PACKER_KEY_FILE ?= packer.pem
PACKER_IMAGE ?= 870326185936.dkr.ecr.us-east-2.amazonaws.com/605data/packer:605
export PACKER_IMAGE PACKER_MANIFEST
export PACKER_CONFIG PACKER_KEY_FILE PACKER_CONFIG_YAML PACKER_CONFIG_JSON

PACKER_REPO:=$(shell basename -s .git `git config --get remote.origin.url`)
PACKER_AMI_NAME:=$(shell python -c "print '${PACKER_REPO}'.replace('ami-', '').replace('ami','')")
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

# this is horrible, but there's no time to cleanup.
# this script should be baked into our packer docker
define PY_PACKER_TAGGER
import os
import json
packer_manifest = os.environ["PACKER_MANIFEST"]
packer_config = os.environ["PACKER_CONFIG_JSON"]
packer_tag = os.environ["PACKER_TAG"]
print "parsing packer manifest at: {}".format(packer_manifest)
assert os.path.exists(packer_manifest), "manifest does not exist!"
manifest = json.loads(open(packer_manifest).read())
print "parsing packer config at: {}".format(packer_config)
assert os.path.exists(packer_config), "config does not exist!"
config = json.loads(open(packer_config).read())
profile = config["builders"][0]["profile"]
artifacts = [b["artifact_id"] for b in manifest["builds"]]
cmd_t = "echo AWS_DEFAULT_REGION={region} AWS_PROFILE={profile} aws ec2 create-tags --resources {ami} --tags Key={tag},Value=True"
artifacts = [artifact.split(":") for artifact in artifacts]
cmds = [cmd_t.format(region=region, profile=profile, ami=packer_ami,
                     tag=packer_tag,) for region, packer_ami in artifacts]
for cmd in cmds:
    print "Executing: {}".format(cmd)
    os.system(cmd)
endef
packer-tag: assert-PACKER_TAG assert-PACKER_MANIFEST
	@printf '$(subst $(newline),\n,${PY_PACKER_TAGGER})'|python /dev/stdin

packer-build: assert-PACKER_IMAGE assert-PACKER_CONFIG packer-get-key
	$(call _announce_target, $@)
	cat ${PACKER_CONFIG} | jq . \
	&& env | grep PACKER_ | docker run -i \
	--env-file /dev/stdin \
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
