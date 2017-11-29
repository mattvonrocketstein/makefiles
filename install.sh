set -x
DEFAULT_REPO="https://github.com/mattvonrocketstein/makefiles.git"
MAKEFILES_REPO=${MAKEFILES_REPO:-${DEFAULT_REPO}}
PROJECT_DIR=`pwd`
LIB_DIR=${PROJECT_DIR}/makefiles
PROJECT_FILE="${PROJECT_DIR}/Makefile"

echo "$LIB_DIR:"
if [ ! -d $LIB_DIR ]; then
  mkdir -p $LIB_DIR
fi

#clone
tmpd=`mktemp -d`
git init $tmpd
pushd $tmpd
git remote add origin $MAKEFILES_REPO
git pull --depth=1 origin master
cp makefiles/* $LIB_DIR
if [ ! -f ${PROJECT_FILE} ]; then
  cp Makefile ${PROJECT_FILE}
else
  echo "not overwriting Makefile already exists"
fi
popd
echo rm -rf "$tmpd"

# git clone --depth=1 $MAKEFILES_REPO
