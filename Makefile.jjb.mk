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

jjb-render-one: assert-path assert-tmp_json assert-render_out
	@ls $$path > /dev/null
	j2 -f json $$path $$tmp_json >> $$render_out

jjb-render-one-inplace: jjb-render-one
	mv $$render_out $$path

jjb-render: require-j2 assert-YAML_TEMPLATE_VAR_FILES
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

require-jjb:
	@jenkins-jobs --version

jjb-validate: require-jjb jjb-render
	$(call _announce_target, $@)
	path=${JJB_INI} make decrypt
	jenkins-jobs --conf ${JJB_INI} test ${JJB_JOB_RENDER_OUT}

jjb-sync: jjb-validate
	$(call _announce_target, $@)
	@ls ${JJB_INI}
	path=${JJB_INI} make decrypt || true
	jenkins-jobs --conf ${JJB_INI} update ${JJB_JOB_RENDER_OUT}
