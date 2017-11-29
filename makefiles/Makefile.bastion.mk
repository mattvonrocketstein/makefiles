BASTION_USER = ubuntu
BASTION_KEY = ~/.ssh/bastion.pem

# Don't use ~ here; Makefile expansion is moody and confusing
BASTION_TMP_DEPLOY_DIR = /home/ubuntu/code/infracode
BASTION_VENV_HOME = /home/ubuntu/venv
export BASTION_USER BASTION_VENV_HOME BASTION_KEY BASTION_TMP_DEPLOY_DIR

ssh-bastion:
	$(call _announce_target, $@)
	ssh ${SSHOPTS} -i ${BASTION_KEY} -l ${BASTION_USER} ${BASTION_IP}


# Target to help use a jump host, for example to get
# inside a VPC and then use it's DNS or subnet IPs.
# This target assumes that the bastion key works equally
# well on the inside, but the target can be easily copied
# and modified to use different keys on different subnets
# or whatever.  Usage example: `host=foo make jump`
jump:  assert-host
	$(call _announce_target, $@)
	scp ${SSHOPTS} -i ${BASTION_KEY} ${BASTION_KEY} \
		${BASTION_USER}@${BASTION_IP}:~/tmp-key
	ssh -tt ${SSHOPTS} \
		-i ${BASTION_KEY} \
		-l ${BASTION_USER} \
		${BASTION_IP} " \
			chmod go-rwx tmp-key; ssh ${SSHOPTS} -i tmp-key \
			-l ${BASTION_USER} $$host; rm -f tmp-key"

# Bastions and jump-hosts often double as a staging host..
# for instance Ansible runs faster if it's inside the VPC
# it's working against, and not doubling up on SSH
# connections from laptops or VPC-external CI servers.
RSYNC_EXCLUDES = --exclude=*.git --exclude=.terraform/*
sync-bastion: assert-src assert-dest
	$(call _announce_target, $@)
	ssh -i ${BASTION_KEY} ${BASTION_USER}@${BASTION_IP} \
		mkdir -p ${BASTION_TMP_DEPLOY_DIR}
	RSYNC_USER=${BASTION_USER} RSYNC_HOST=${BASTION_HOST} \
	RSYNC_KEY=${BASTION_KEY} RSYNC_SRC=$$src/* \
	RSYNC_DEST=$$dest \
	make rsync

# Undo the bastion-sync target, removing the code we
# provisioned with and the keys we used to connect
unsync-bastion:
	$(call _announce_target, $@)
	ssh -i ${BASTION_KEY} ${BASTION_USER}@${BASTION_IP} "\
		rm -rf ${BASTION_TMP_DEPLOY_DIR} && rm ${BASTION_KEY}"
