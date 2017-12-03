# example: embedding python in your makefile, then executing it from a target.
# the export is crucial to get the script value, with unmolested newlines, into
# the shell
define PY_EXAMPLE
x = 1
print x
endef
export PY_EXAMPLE
test-python:
	printf "$${PY_EXAMPLE}" | python
