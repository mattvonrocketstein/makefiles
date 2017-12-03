# usage during inclusion:
#
#   in including makefile, suggested setup for vars is like this:
#
#   CF_KEY_DIR=${SRC_ROOT}/keys
#   CF_KEY_NAME=jenkins-toposphere
#   CF_KEY_PATH=${CF_KEY_DIR}/${CF_KEY_NAME}.pem
#   export CF_KEY_NAME CF_KEY_DIR CF_KEY_PATH

require-iidy:
	@iidy --version

cf-key-destroy: assert-CF_KEY_PATH assert-CF_KEY_NAME
	$(call _announce_target, $@)
	echo "keypath: $${CF_KEY_PATH}"
	rm -f "$${CF_KEY_PATH}"
	aws ec2 delete-key-pair --key-name $${CF_KEY_NAME}

cf-key-create: require-jq assert-CF_KEY_PATH assert-CF_KEY_NAME
	$(call _announce_target, $@)
	if [ -f $${CF_KEY_PATH} ]; then \
		MSG="key $${CF_KEY_PATH} already exists on filesystem\n" \
		MSG="$${MSG} remove it if you really want to procede" \
		make fail; \
	fi
	aws ec2 create-key-pair --key-name $${CF_KEY_NAME} | \
	jq -r '.KeyMaterial' > $${CF_KEY_PATH}

cf-validate: assert-path
	$(call _announce_target, $@)
	aws cloudformation validate-template --template-body=file://$$path

cf-events: cf-history
cf-history: assert-stack
	iidy watch-stack $$stack

cf-exports:
	$(call _announce_target, $@)
	aws cloudformation list-exports

cf-plan: cf-cs
cf-cs: require-iidy assert-path
	outfile=cloudformation-tmp-change-set; \
	iidy create-changeset $$path $${outfile};

cf-list:  require-iidy
	iidy list-stacks

cf-describe: require-iidy assert-stack
	iidy describe-stack $$stack

cf-render: require-iidy assert-path
	iidy render $$path

# static-analysis:
cf-show-imports: require-ack assert-path
	ack "Fn::ImportValue" $$path
cf-imports: cf-show-imports

# cf-update:
# 	aws cloudformation update-stack \
# 	--stack-name cloudtrail-security-stack \
# 	--template-body file://wonk/security_alerts.yml \
# 	--parameters '[{"ParameterKey": "Email", "UsePreviousValue": true}, {"ParameterKey": "LogGroupName", "UsePreviousValue": true}]'


# cf-create:
# 	$(call _announce_target, $@)
# 	AWS_PROFILE=${AWS_PROFILE} aws cloudformation \
# 	create-stack --template-body \
# 	file://cf/stack.yml --stack-name jenkins \
# 	--parameters file://cf/input.yaml
