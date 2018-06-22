##
# dynamically and DRYly reads the ruby version from
# .ruby_version, converting the `-` to `:` so we get
# back a docker image we can pull
##
RUBY_IMAGE:=$(shell \
	cat .ruby-version \
	| python -c"import sys; print sys.stdin.read().strip().replace('-', ':') \
	")
export RUBY_IMAGE


# helper that fetches ruby dependencies without installing,
# and uses docker so that a ruby stack is not required.
# this uses host SSH keys for clones to avoid secrets in
# container, and does locale stuff to avoid ruby complaining
# about "invalid byte sequence in US-ASCII (Argument Error)"
ruby-fetch-deps: assert-RUBY_IMAGE
	docker run -i --rm \
  --workdir /app \
	-e LANG=C.UTF-8 \
  -v `pwd`:/app \
	-v ~/.ssh:/root/.ssh \
	$(value RUBY_IMAGE) \
  bash -c "bundle package --all --no-install"
