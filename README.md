<table>
  <tr>
    <td colspan=2><strong>
      makefiles
      </strong>&nbsp;&nbsp;&nbsp;&nbsp;
      <small><small>
        <a href=#Features>Features</a> |
        <a href=#Usage>Usage</a> |
        <a href=#Rationale>Rationale</a>
      </small><small>
    </td>
  </tr>
  <tr>
    <td width=15%>
      <a href=https://github.com/mattvonrocketstein/makefiles>
        <img src=img/icon.png style="width:150px">
      </a>
    </td>
    <td>
I'm honestly the type of person who never thought they would have a "makefiles" repository, but here it is.  This is a library of specific, useful, and reusable code for automating stuff with GNU Make.
    </td>
  </tr>
</table>

## About

If you, like me, are suspicious of Makefile-based automation, jump to the <a href=#rationale>Rationale section</a> of this documentation for some more information/advocacy.  To find out if this might be useful for you, see <a href=#features>Features section</a> to get an overview of some of the public API, then see the <a href=#usage>Usage</a> section to jump in.

## Versions

* GNU make 3.81, i386-apple-darwin11.3.0
* GNU Make 4.1 Built for x86_64-pc-linux-gnu

## Features

**[Makefile.boilerplate.mk](Makefile.boilerplate.mk):** The only file that's not supposed to be use as library/makefile-include, this file contains a suggested template for your top-level project makefile.

**[Makefile.base.mk](Makefile.base.mk):** Baseline stuff that pretty much all the other Makefile's will require, including colored output for users and assertions on environment variables.  The goal is that this should be the only place that will declare Makefile-functions, because that quickly gets into esoteric rituals.  The rest of these files use make-targets.

**[Makefile.ansible-vault.mk](Makefile.ansible-vault.mk):** [Ansible vault](https://docs.ansible.com/ansible/2.4/vault.html) automation for light-weight crypto.  This is useful stuff for handling in-repo secrets responsibly.

**[Makefile.ansible.mk](Makefile.ansible.mk):** Targets that can help give [Ansible](https://docs.ansible.com/) projects concise and reusable entrypoints.

**[Makefile.aws-ecs.mk](#):** [AWS ECS](http://docs.aws.amazon.com/cli/latest/reference/ecs/) related workflows

**[Makefile.bastion.mk](#):** Various [bastion host](https://en.wikipedia.org/wiki/Bastion_host) workflows, covering things related to ssh, rsync, jump hosts, and Ansible.

**[Makefile.cloudformation.mk](#):** AWS [Cloudformation](https://aws.amazon.com/cloudformation/) workflows

**[Makefile.docker.mk](#):** [Docker](https://www.docker.com/) workflows, including linting, and helpers for working with (potentially remote) [docker-compose](https://docs.docker.com/compose/) based services.

**[Makefile.git.mk](#):** Git VCS workflows, mostly the uncommon stuff I often struggle to remember (submodules, sync-from-upstream, etc).

**[Makefile.json.mk](#):** JSON parsing and transformation workflows, many of which use [jq](#placeholder).  There's also helpers for validation, rendering templated JSON, and converting JSON to YAML.

**[Makefile.ssh.mk](#):**  SSH workflow automation targets, including keygen, interactive shells, rsync & scp stuff.  This is here largely for chaining to it, and is a useful foundation for much of the other automation.

**[Makefile.terraform.mk](#):**  Terraform workflows, especially things that help to access, filter, and convert [terraform outputs](#) so that it can be passed into other systems like ansible or cloudformation.

## Design

**Include files: Makefile.*.mk**:  Automation tools in this library are bundled into domain-specific files that should publish discrete, lightweight automation tools.  These are usually designed to be used as [make-includes]([include](https://www.gnu.org/software/make/manual/html_node/Include.html)) in a top-level Makefile.  For example [Makefile.docker.mk](Makefile.docker.mk) contains helpers for docker-related workflows.  [Makefile.boilerplate.mk](Makefile.boilerplate.mk) shows an example of the type of top-level Makefile that could `include` [Makefile.docker.mk](Makefile.docker.mk).

**Makefile-Targets:**  Discrete automation tasks are implemented as make-targets, and continuing with the [Makefile.docker.mk example](Makefile.docker.mk), could be invoked like `make docker-lint`.

**Target Input/Parameters:** Some few make-targets defined in this library work with unix pipes, but most follow [12-factor principles](https://12factor.net/config) and are made parametric by usage of environment variables.  Thus an invocation of the `docker-lint` target could also be something like this:  `path=subfolder/Dockerfile make docker-lint`

## Usage

### As a Project Automation Library

The usage guide that follows assumes your project doesn't already have a top level Makefile.  If you do already have one, you'll want to take a look at the example top-level makefile [here](Makefile.boilerplate.mk) and figure out how to combine things for the results you want.

We'll also assume you want to set things up so as to potentially track upstream changes in this automation library (or your fork of it) but that's optional.  

Inside your project directory run something like this:

    git submodule add git@github.com:mattvonrocketstein/makefiles.git .makefiles
    git submodule update --init
    cp .makefiles/Makefile.boilerplate.mk Makefile

Now edit your toplevel Makefile to only include the domain-specific automation stuff that you need.

Assuming you have a recent version of git you should also be able to `git clone --recursive git://github.com/user/myproject.git` to clone your project and the submodule in one step.

### Standalone Usage

Placeholder

## Rationale

This section covers some of the rationale behind an automation library that's (at least partially) based around Makefiles.  Makefile based automation is not my favorite thing, for a variety of reasons.  In most ways writing Makefiles is significantly nicer than a pure-bash library, yet far worse than having an actual programming language at your disposal.  In particular quoting and variable interpolation is often surprising and code-reuse can be challenging.  

So why use it if it's a pain to write?  A big part of the reason is because it's easy to run, and close enough to the shell that it's perfect for project automation.  I've also noticed that you're writing stuff that becomes overly difficult in Makefiles, you are probably NOT writing "project automation", and might be writing something that would be better expressed as a "one-off tool", i.e. a tool that is *external* to the project.

**Make is simple**, at least compared to other automation frameworks.  In a world with Gulpfiles, Rakefiles, Fabfiles, and many other options for project automation, Makefile's feel like a lightweight and mostly dependency-free approach.

**Make is lean**, both in terms of concepts and dependencies.  Sure, many development environments might have access to python or ruby too, but Makefiles are leaner and don't require the rvm or virtualenv setup step.  

**Makefiles are language agnostic** and don't commit themselves to any preference for say Python, Ruby, or JS.  Polyglot development shops may especially appreciate it as a reasonable middle ground between different teams.  A further issue is that implementing your core automation library with, for instance, Ruby/Rake would tend to not only couple you to Ruby but to dictate your base version of a Ruby stack.

**Make is ubiquitous**.  Really, it's almost everywhere already, and it's nice that any CI server, docker container, or local development environment already has `make`.  

**Make is fairly transparent** in terms of both it's source and it's execution context, and fairly traceable compared with a fat binary build tool or a docker container.
