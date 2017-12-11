
ssh-bastion:
	$(call _announce_target, $@)
	SSH_KEY=$(value BASTION_KEY) SSH_USER=$(value BASTION_USER) \
	SSH_HOST=$(value BASTION_IP) \
	${MAKE} ssh-generic
bastion-ssh: ssh-bastion


# Target to help use a jump host, for example to get
# inside a VPC and then use it's DNS or subnet IPs.
# This target assumes that the bastion key works equally
# well on the inside, but the target can be easily copied
# and modified to use different keys on different subnets
# or whatever.  Usage example: `host=foo make jump`
jump:  assert-host set-bastion
	$(call _announce_target, $@)
	eval $$(ssh-agent) && ssh-add $(value BASTION_KEY) && \
	SSH_KEY=$(value BASTION_KEY) \
	SSH_USER=$(value BASTION_USER) \
	SSH_HOST=$(value BASTION_IP) \
	SSH_CMD='ssh $(value SSH_OPTS) -l $(value BASTION_USER) $(value host) ' \
 	${MAKE} ssh-generic
bastion-jump: jump

# Bastions and jump-hosts often double as a staging host..
# for instance Ansible runs faster if it's inside the VPC
# it's working against, and not doubling up on SSH
# connections from laptops or VPC-external CI servers.
RSYNC_EXCLUDES = --exclude=*.git --exclude=.terraform/* --exclude=.DS_Store
bastion-sync: assert-BASTION_IP
	$(call _announce_target, $@)
	SSH_KEY=$(value BASTION_KEY) \
	SSH_USER=$(value BASTION_USER) \
	SSH_HOST=$(value BASTION_IP) \
	SSH_CMD='mkdir -p $(value BASTION_TMP_DEPLOY_DIR)' \
	make ssh-generic

	SSH_KEY=$(value BASTION_KEY) SRC=$(value BASTION_KEY) \
	DEST=/home/ubuntu/.ssh \
	SSH_USER=$(value BASTION_USER) \
	SSH_HOST=$(value BASTION_IP) \
	make scp-generic

	pushd $(value SRC_ROOT) && \
	RSYNC_SRC=. \
	RSYNC_USER=$(value BASTION_USER) \
	RSYNC_HOST=$(value BASTION_IP) \
	RSYNC_KEY=$(value BASTION_KEY) \
	RSYNC_DEST=$(value BASTION_TMP_DEPLOY_DIR) \
	make rsync

sync-bastion: bastion-sync

# Undo the bastion-sync target, removing the code we
# provisioned with and the keys we used to connect
bastion-unsync:
	$(call _announce_target, $@)
	SSH_KEY=${BASTION_KEY} SSH_USER=${BASTION_USER} SSH_HOST={BASTION_IP}
	SSH_CMD='rm -rf ${BASTION_TMP_DEPLOY_DIR} && rm -f "${BASTION_KEY}"' make ssh-generic
