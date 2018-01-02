# Makefile.pelican.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   common workflows with the pelican static blog generator
#
# REQUIRES: (system tools)
#	  * pelican
#   * tree
#   * twistd
#
# DEPENDS: (other makefiles and make-targets)
#   * makefiles/Makefile.base.mk
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `placeholder`:
#   PIPED TARGETS: (stdin->stdout)
#     * `placeholder`:
#

PELICAN_PORT ?= 5000

pelican-serve: require-twistd assert-PROJECT_NAME assert-PELICAN_PORT
	$(call _announce_target, $@)
	$(call _INFO, 'serving at http://localhost:$$PELICAN_PORT/$$PROJECT_NAME/ ')
	twistd -n web --port ${PELICAN_PORT} --path .

pelican-archive-clean:
	$(call _announce_target, $@)
	rm -f \
	${PROJECT_NAME}.tar \
	${PROJECT_NAME}.tar.gz \
	${PROJECT_NAME}-${BUILD_NUMBER}.tar.gz

pelican-archive: pelican-archive-clean
	$(call _announce_target, $@)
	tree -L 3 ${PROJECT_NAME}
	tar -cvf ${PROJECT_NAME}.tar ${PROJECT_NAME}
	gzip ${PROJECT_NAME}.tar
	mv ${PROJECT_NAME}.tar.gz ${PROJECT_NAME}-${BUILD_NUMBER}.tar.gz
	cp -v ${PROJECT_NAME}-${BUILD_NUMBER}.tar.gz artifact.tgz

pelican-build-generic: assert-PELICAN_CONF
	$(call _announce_target, $@)
	cd ${SRC_ROOT}; \
	pelican --debug -s $$PELICAN_CONF -o $(value PELICAN_GEN_PATH)

pelican-build: assert-PELICAN_DEFAULT_ENV
	$(call _announce_target, $@)
	PELICAN_CONF=$${PELICAN_DEFAULT_ENV} make pelican-build-generic

pelican-clean: assert-PELICAN_GEN_PATH
	$(call _announce_target, $@)
	ls ${PELICAN_GEN_PATH}/index.html || exit 0
	rm -rf "${PELICAN_GEN_PATH}"
	mkdir -p ${PELICAN_GEN_PATH}

pelican-rebuild: pelican-clean pelican-build
