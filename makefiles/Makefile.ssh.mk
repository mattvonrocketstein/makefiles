# Generic rsync method, suitable for synchronizing with a remote codebase
#
# usage: see main Makefile for demo
RSYNC_BASE_CMD := rsync -az --force --delete --progress
RSYNC_EXCLUDES = --exclude=*.git --exclude=.terraform/*
rsync: assert-RSYNC_USER assert-RSYNC_KEY assert-RSYNC_DEST assert-RSYNC_SRC assert-RSYNC_HOST
	$(call _announce_target, $@)
	eval $$(ssh-agent) && ssh-add ${RSYNC_KEY} && \
	ssh $$RSYNC_USER@$$RSYNC_HOST mkdir -p `dirname $$RSYNC_DEST` && \
	${RSYNC_BASE_CMD} \
		--rsh "ssh -i $$RSYNC_KEY -p 22" \
		${RSYNC_EXCLUDES} \
		$$RSYNC_SRC $$RSYNC_USER@$$RSYNC_HOST:$$RSYNC_DEST;

# Generic SSH target.  Don't rename this target to `ssh`, that name is too
# useful elsewhere (site specific) and would probably get overridden confusingly.
# This target requires many `SSH_*` environment variables to be passed in, but
# we do use a global (makefile) variable for SSH_OPTS.  Makefiles including this
# file may wish to override
#
# usage example: see main Makefile for demo
SSH_OPTS := -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
ssh-generic: assert-SSH_USER assert-SSH_HOST assert-SSH_KEY
	$(call _announce_target, $@)
	ssh -tt ${SSH_OPTS} \
	 	-i $${SSH_KEY} -l $${SSH_USER} \
		$${SSH_HOST} $${SSH_CMD}
