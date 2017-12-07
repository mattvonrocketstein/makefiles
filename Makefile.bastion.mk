BASTION_USER = ubuntu
BASTION_KEY = ~/.ssh/bastion.pem

# Don't use ~ here; Makefile expansion is moody and confusing
BASTION_TMP_DEPLOY_DIR = /home/ubuntu/code/infracode
BASTION_VENV_HOME = /home/ubuntu/venv
export BASTION_USER BASTION_VENV_HOME BASTION_KEY BASTION_TMP_DEPLOY_DIR

ssh-bastion:
	$(call _announce_target, $@)
	SSH_KEY=${BASTION_KEY} SSH_USER=${BASTION_USER} \
	SSH_HOST=${BASTION_IP} \
	${MAKE} ssh-generic
bastion-ssh: ssh-bastion

set-bastion:
	$(call _announce_target, $@)
	$(eval BASTION_IP ?= $${BASTION_IP:-neverSet})
	@echo set BASTION_IP: ${BASTION_IP}

# Target to help use a jump host, for example to get
# inside a VPC and then use it's DNS or subnet IPs.
# This target assumes that the bastion key works equally
# well on the inside, but the target can be easily copied
# and modified to use different keys on different subnets
# or whatever.  Usage example: `host=foo make jump`
jump:  assert-host set-ssh-cmd set-bastion
	$(call _announce_target, $@)
	eval $$(ssh-agent) && ssh-add ${BASTION_KEY} && \
	SSH_KEY=${BASTION_KEY} \
	SSH_USER=${BASTION_USER} \
	SSH_HOST=${BASTION_IP} \
	SSH_CMD='ssh ${SSH_OPTS} -l ${BASTION_USER} $${host} ' \
	make -f $(THIS_MAKEFILE) ssh-generic
bastion-jump: jump
#; ssh ${SSH_OPTS} -i tmp-key -l ${BASTION_USER} $${host}; rm -f tmp-key

# Bastions and jump-hosts often double as a staging host..
# for instance Ansible runs faster if it's inside the VPC
# it's working against, and not doubling up on SSH
# connections from laptops or VPC-external CI servers.
RSYNC_EXCLUDES = --exclude=*.git --exclude=.terraform/* --exclude=.DS_Store
bastion-sync:
	$(call _announce_target, $@)
	SSH_KEY=${BASTION_KEY} SSH_USER=${BASTION_USER} SSH_HOST=${BASTION_IP} \
	SSH_CMD='mkdir -p ${BASTION_TMP_DEPLOY_DIR}' \
	make ssh-generic

	SSH_KEY=${BASTION_KEY} SRC=${BASTION_KEY} DEST=/home/ubuntu/.ssh \
	SSH_USER=${BASTION_USER} SSH_HOST=${BASTION_IP} make scp-generic

	pushd ${SRC_ROOT} && RSYNC_USER=${BASTION_USER} RSYNC_HOST=${BASTION_IP} \
	RSYNC_KEY=${BASTION_KEY} RSYNC_SRC=. \
	RSYNC_DEST=${BASTION_TMP_DEPLOY_DIR} \
	make rsync

sync-bastion: bastion-sync

# Undo the bastion-sync target, removing the code we
# provisioned with and the keys we used to connect
bastion-unsync:
	$(call _announce_target, $@)
	SSH_KEY=${BASTION_KEY} SSH_USER=${BASTION_USER} SSH_HOST={BASTION_IP}
	SSH_CMD='rm -rf ${BASTION_TMP_DEPLOY_DIR} && rm -f "${BASTION_KEY}"' make ssh-generic
