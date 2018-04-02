# Makefile.aws-kms.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   really basic kms workflows and usage patterns.
#
# REQUIRES: (system tools)
#   * aws CLI
#
# DEPENDS: (other makefiles)
#   * Makefile.base.mk
#
# INTERFACE: (primary targets intended for export; see usage examples)
#
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `kms-encrypt`: Encrypt file `INPUT` contents with KMS key `KEY_NAME`
#
#   PIPED TARGETS: (stdin->stdout)
#     * `kms-encrypt-pipe`: Encrypt stdin with KMS key `KEY_NAME`
#

kms-encrypt-pipe: assert-KEY_NAME
	@INPUT=/dev/stdin make kms-encrypt

kms-encrypt: require-aws assert-KEY_NAME assert-INPUT
	@aws kms encrypt \
	--key-id alias/$$KEY_NAME \
	--plaintext $$INPUT \
	--query CiphertextBlob \
	--output text
