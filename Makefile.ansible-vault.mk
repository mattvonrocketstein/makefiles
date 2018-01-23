# Makefile.ansible-vault.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing
#   various lightweight crypto workflows using `ansible-vault`. For
#   more info on ansible-vault, see also:
#      https://docs.ansible.com/ansible/2.4/vault.html
#
# REQUIRES: (system tools)
#   * ansible-vault
#
# DEPENDS: (other makefiles)
#   * makefiles/Makefile.ssh.mk
#
# INTERFACE: (primary targets intended for export; see usage examples)
#
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `vault-encrypt-path`: encrypt $path with standard key
#     * `vault-decrypt-path`: decrypt $path with standard key
#     * `vault-rekey-path`: rekey $path with given $oldkey, $newkey
#     * `vault-edit`: decrypted $path, edit interactively & re-encrypt
#
#   PIPED TARGETS: (stdin->stdout)
#     * `vault-secret`: encrypt secret on stdin to stdout
#

ANSIBLE_ROOT ?= ${SRC_ROOT}/ansible
ANSIBLE_VAULT_EXEC ?= ansible-vault
ANSIBLE_VAULT_FILES_PATTERN:=.*vault.*
# export EDITOR ANSIBLE_VAULT_EXEC ANSIBLE_ROOT ANSIBLE_VAULT_EXEC

# target: `vault-base`: helper for other targets
vault-base: assert-ANSIBLE_VAULT_PASSWORD_FILE assert-VAULT_CMD
	$(value ANSIBLE_VAULT_EXEC) $(value VAULT_CMD)

# target `vault-encrypt-path`: encrypt a file
# usage example: encrypt a file at a certain path
#     $ path=/far/bar/baz make encrypt-path
vault-encrypt-path: assert-path
	$(call _announce_target, $@)
	@cat $(value path) | \
	head -n1 | grep --no-messages ANSIBLE_VAULT > /dev/null || \
	VAULT_CMD="encrypt $(value path)" make vault-base
encrypt-path: vault-encrypt-path
encrypt: encrypt-path


# target `vault-lock`:
#   encrypts all files in repo matching pattern.
#   (this can be useful for implementing commit hooks)
#
# example: decrypt a file at a certain path
#     $ path=/far/bar/baz make decrypt-path
vault-lock:
	git diff --staged --name-only | \
	grep ${ANSIBLE_VAULT_FILES_PATTERN} | \
	xargs -n 1 -I {} bash -ex -c "path={} make encrypt"


# target `vault-decrypt-path`:
# example: decrypt a file at a certain path
#     $ path=/far/bar/baz make decrypt-path
decrypt: decrypt-path
decrypt-path: vault-decrypt-path
vault-decrypt-path: assert-path
	$(call _announce_target, $@)
	@cat $(value path) | \
	head -n1 | grep --no-messages ANSIBLE_VAULT > /dev/null && \
	VAULT_CMD="decrypt $(value path)" make vault-base || \
	$(call _INFO, '$${path} is not encrypted')


# target `vault-rekey`:
# usage example: rekey one file given $oldkey and $newkey
#     $ path=/far/bar/baz oldkey=old.key newkey=new.key make vault-rekey
vault-rekey: assert-oldkey assert-newkey assert-path
	$(call _announce_target, $@)
	${ANSIBLE_VAULT_EXEC} encrypt \
		--new-vault-id=$$path \
		--new-vault-password-file=$$newkey \
		--vault-password-file=$$oldkey \
		$$path

# target `vault-secret`:
#
# usage examples: encode secret and put it on a file, or in the clipboard
#   $ echo hunter2 | make secret > password.txt
#   $ echo hunter2 | make secret | pbcopy
vault-secret: assert-ANSIBLE_VAULT_PASSWORD_FILE
	$(call _announce_target, $@)
	@VAULT_CMD="encrypt_string -" make vault-base
secret: vault-secret
vault-unsecret: assert-ANSIBLE_VAULT_PASSWORD_FILE
	$(call _announce_target, $@)
	@VAULT_CMD="decrypt -" make vault-base
unsecret: vault-unsecret

# usage examples: edit encrypted file in-place
#   $ path=/my/secret make vault-edit
#   $ echo hunter2 | make secret | pbcopy
VAULT_EDITOR:=nano
vault-edit: assert-ANSIBLE_VAULT_PASSWORD_FILE assert-path
	$(call _announce_target, $@)
	@# atom breaks otherwise, at least with my settings
	EDITOR = ${VAULT_EDITOR} \
	VAULT_CMD="edit $(value path)" \
	make vault-base
