
SSH_OPTS := -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# Generic rsync method, suitable for synchronizing with a remote codebase
#
# usage: see main Makefile for demo
RSYNC_BASE_CMD := rsync -az --force --delete --progress
RSYNC_EXCLUDES = --exclude=*.git --exclude=.terraform/*
rsync: assert-RSYNC_USER assert-RSYNC_KEY assert-RSYNC_DEST assert-RSYNC_SRC assert-RSYNC_HOST
	$(call _announce_target, $@)
	eval $$(ssh-agent) && ssh-add $(value RSYNC_KEY) && \
	ssh $$RSYNC_USER@$$RSYNC_HOST mkdir -p `dirname $$RSYNC_DEST` && \
	$(value RSYNC_BASE_CMD) \
		--rsh "ssh ${SSH_OPTS} -i $$RSYNC_KEY -p 22" \
		$(value RSYNC_EXCLUDES) \
		$$RSYNC_SRC $$RSYNC_USER@$$RSYNC_HOST:$$RSYNC_DEST;

# Generic SSH target.  Don't rename this target to `ssh`, that name is too
# useful elsewhere (site specific) and would probably get overridden confusingly.
# This target requires many `SSH_*` environment variables to be passed in, but
# we do use a global (makefile) variable for SSH_OPTS.  Makefiles including this
# file may wish to override
#
# usage example: see main Makefile for demo
# set-ssh-cmd:
# 	$(call _announce_target, $@)
# 	$(eval SSH_CMD ?= ${SSH_CMD:-bash})
# 	@echo 'set SSH_CMD: ${SSH_CMD}'

ssh-generic: assert-SSH_USER assert-SSH_HOST assert-SSH_KEY
	$(call _announce_target, $@)
	$(eval SSH_CMD ?= bash)
	$(call _INFO, '$(value SSH_CMD)')
	ssh -A -tt $(value SSH_OPTS) \
	-i $(value SSH_KEY) -l $(value SSH_USER) $(value SSH_HOST) \
	"$(value SSH_CMD)"
scp-generic: scp-push
scp-push: assert-SSH_USER assert-SSH_HOST assert-SSH_KEY
	$(call _announce_target, $@)
	scp $(value SSH_OPTS) -i $(value SSH_KEY) $(value SRC) $(value SSH_USER)@$(value SSH_HOST):$(value DEST)
scp-pull: assert-SSH_USER assert-SSH_HOST assert-SSH_KEY
	$(call _announce_target, $@)
	scp $(value SSH_OPTS) -i $(value SSH_KEY) $(value SSH_USER)@$(value SSH_HOST):$(value SRC) $(value DEST)

keygen: assert-KEY
	ssh-keygen -N '' -C $$KEY -f $$KEY
ssh-keygen: keygen
