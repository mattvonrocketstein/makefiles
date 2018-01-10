# Makefile.jjb.mk:
#
# DESCRIPTION:
#   A makefile suitable for including in a parent makefile, smoothing various
#   jenkins-job builder workflows and usage patterns.  For more info on JJB,
#   see also: https://github.com/openstack-infra/jenkins-job-builder
#
# REQUIRES: (system tools)
#   * xargs
#   * jenkins-jobs
#   * j2
#
# DEPENDS: (other makefiles)
#   * Makefile.json.mk ()
#   * Makefile.yaml.mk ()
#   * Makefile.base.mk (asserts, console output helpers)
#
# INTERFACE: (primary targets intended for export; see usage examples)
#   STANDARD TARGETS: (communicate with env-vars or make-vars)
#     * `jjb-render`:
#     * `jjb-validate`:
#     * `jjb-sync`:
#   PIPED TARGETS: (stdin->stdout)
#     * None
#

##
# VARS: (toplevel overrides, suggested additions for usage as Makefile include)
##
JJB_INI ?= jenkins.ini.vault
JJB_JOB_TEMPLATE_DIR ?= ${SRC_ROOT}/jenkins-jobs
JJB_JOB_RENDER_DIR ?= ${SRC_ROOT}/.jjb-render
JJB_JOB_RENDER_OUT ?= ${JJB_JOB_RENDER_DIR}/rendered-jobs.yml

# assert jenkins-jobs is in $PATH
require-jjb:
	@jenkins-jobs --version

# validate whatever yaml we ultimately rendered
# (see default rendering options below, or make your own)
jjb-validate: require-jjb jjb-render jjb-decrypt-config
	$(call _announce_target, $@)
	jenkins-jobs --conf ${JJB_INI} test ${JJB_JOB_RENDER_OUT}

# this target assumes that ${JJB_INI} might be using
# encryption based on Makefile.ansible-vault.mk.
# if your ${JJB_INI} isn't encrypted or is .gitignored,
# or if you don't want a depedency on ansible,
# override this target to use set it as NOOP
jjb-decrypt-config:
	@ls ${JJB_INI}
	path=${JJB_INI} make decrypt || true

# sync whatever yaml we've validated & rendered
jjb-sync: jjb-validate jjb-decrypt-config
	$(call _announce_target, $@)
	jenkins-jobs -l DEBUG \
	--conf ${JJB_INI} update ${JJB_JOB_RENDER_OUT}

# simple renderer, just concatenates yaml
# files which are stored flatly, with no
# nested subdirs, inside a folder $input
jjb-render-concat:
	$(call _announce_target, $@)
	input=${JJB_JOB_TEMPLATE_DIR} \
	output=${JJB_JOB_RENDER_OUT} \
	make yaml-concat

jjb-render:
	$(call _announce_target, $@)
	make ${JJB_RENDER_TARGET}

# complex renderer for JJB yaml which is itself
# templated, say with k/v's from ${ANSIBLE_ROOT}/vars.yml
jjb-render-complex: require-j2 assert-YAML_TEMPLATE_VAR_FILES
	$(call _announce_target, $@)
	$(eval TMP_YML = $(value JJB_JOB_RENDER_DIR)/.tmp.yml)
	$(eval TMP_JSON = $(value JJB_JOB_RENDER_DIR)/.tmp.json)
	$(eval export TMP_YML TMP_JSON)
	$(call _show_env, "\(TMP\|JJB\)")
	@$(call _INFO, "refreshing")
	rm -rf "$(value JJB_JOB_RENDER_DIR)"
	mkdir -p $(value JJB_JOB_RENDER_DIR)
	cp -rfv $(value JJB_JOB_TEMPLATE_DIR)/* $(value JJB_JOB_RENDER_DIR)
	@# concatenate CM variables files into a single yaml file
	@# NB: this file contains templated values!
	@$(call _INFO, "concatenating")
	echo "" > $(value TMP_YML)
	echo $$YAML_TEMPLATE_VAR_FILES | tr ',' '\n' | \
	xargs -I {} bash -ex -c 'cat {} | tee -a ${TMP_YML}'
	@# convert vars-yaml-file template to json file template
	@# then perform a "iterated render", where the json is
	@# used to render itself.  this should result in a flat
	@# file of CM variables that are NOT templated
	@$(call _INFO, "rendering-stage-1")
	cat $(value TMP_YML) | make yaml-to-json > $(value TMP_JSON)
	path=$(value TMP_JSON) make json-irender > $(value TMP_JSON).rendered
	@# for each (templated) jenkins-jobs-builder yaml
	@# file, render it with the CM variable json, we
	@# made before.  the results are appended to the
	@# "JJB_JOB_RENDER_OUT" file.  after this is done,
	@# jenkins-job-builder can use the YAML.
	tree $(value JJB_JOB_RENDER_DIR)
	@$(call _INFO, "rendering-stage-2")
	find $(value JJB_JOB_RENDER_DIR)/*.groovy -type f | tr ' ' '\n' | \
	xargs -I {} bash -c 'path={} render_out={}.tmp tmp_json=${TMP_JSON}.rendered make jjb-render-one-inplace; '
	find $(value JJB_JOB_RENDER_DIR)/*.yml -type f | tr ' ' '\n' | \
	xargs -I {} bash -c 'path={} render_out=${JJB_JOB_RENDER_OUT} tmp_json=${TMP_JSON}.rendered make jjb-render-one'
	$(call _INFO, 'rendered jobs successfully')
	tree $(value JJB_JOB_RENDER_DIR)
	$(call _INFO, '${JJB_JOB_RENDER_OUT}')
# helper for jjb-render-complex
jjb-render-one: assert-path assert-tmp_json assert-render_out
	@ls $$path > /dev/null
	j2 -f json $$path $$tmp_json >> $$render_out

# helper for jjb-render-complex
jjb-render-one-inplace: jjb-render-one
	mv $$render_out $$path
