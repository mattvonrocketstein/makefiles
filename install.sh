set -x

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
echo "$LIB_DIR:"
if [ ! -d $LIB_DIR ]; then
  mkdir -p $LIB_DIR
fi



# git clone --depth=1 $MAKEFILES_REPO
