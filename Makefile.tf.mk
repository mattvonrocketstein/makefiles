# A target to ensure fail-fast if terraform is not present
require-tf:
	terraform --version &> /dev/null

# Target for simple proxy to terraform, "refresh" subcommand
tf-refresh:
	$(call _announce_target, $@)
	terraform refresh

# Target for simple proxy to terraform, "plan" subcommand
tf-plan:
	$(call _announce_target, $@)
	terraform plan
# Target for simple proxy to terraform, "apply" subcommand
tf-apply:
	$(call _announce_target, $@)
	terraform apply

# Target for simple proxy to terraform, "taint" subcommand
tf-taint:
	$(call _announce_target, $@)
	terraform taint

# Target to create a png graph of terraform resources.
# Requires dot.  TODO: see what can be done here
# to make a graph that ISNT so huge it's worthless
tf-graph:
	$(call _announce_target, $@)
	terraform graph | dot -Tpng > graph.png
