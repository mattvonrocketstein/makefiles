#
#
#

MAKEFILES_REPO_DEFAULT:= "https://github.com/mattvonrocketstein/makefiles.git"
MAKEFILES_REPO := ${MAKEFILES_REPO:-${MAKEFILES_REPO_DEFAULT}}
PROJECT_DIR := `pwd`
PROJECT_FILE := ${PROJECT_DIR}/Makefile
MAKEFILES_LIB_DIR_DEFAULT := ${PROJECT_DIR}/makefiles
MAKEFILES_LIB_DIR := $${MAKEFILES_LIB_DIR_DEFAULT:-${MAKEFILES_LIB_DIR_DEFAULT}

library-update:
	tmpd=${CLONE_DIR:-`mktemp -d`} \
	git init $tmpd \
	pushd $tmpd \
	git remote add origin ${MAKEFILES_REPO} \
	git pull --depth=1 origin master \
	cp makefiles/* ${MAKEFILES_LIB_DIR} \
	@if [ ! -f ${PROJECT_FILE} ]; then \
		cp Makefile ${PROJECT_FILE} \
	else \
		echo "not overwriting Makefile already exists" \
	fi

library-update:
