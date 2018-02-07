#
# Makefile.examples-embedded.mk:
#
#   Demonstrations / test-cases for executing various kinds
#   of embedded scripts.  Granted, doing this is always a hack,
#   and there's no doubt this is a very ugly thing stylistically.
#   Still, sometimes when you really need a single piece of
#   specific automation that changes infrequently, it's worth it
#   to avoid creating more files, more repos, etc.
#

# really, don't mess with this.  it looks like there's two
# newlines but there's some kind of magic.
define newline


endef

# 'don't use single-quotes here'
define PYTHON_CODE
import time
print "hello world"
while 1:
	print time.time()
endef

# 'don't use single-quotes here'
define SHELL_CODE
while true; do
	echo "current time: `date`"
sleep 1
done
endef

embedded-bash:
	@printf '$(subst $(newline),\n,${SHELL_CODE})'|bash -ex -l

embedded-python:
	@printf '$(subst $(newline),\n,${PYTHON_CODE})'|python /dev/stdin
