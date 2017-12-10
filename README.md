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

If you, like me, are suspicious of Makefile-based automation, jump to the <a href=#rationale>Rationale section</a> of this documentation for some more information/advocacy.  To find out if this might be useful for you, see <a href=#features>Features section</a> to get an overview of what's on tap, then see the <a href=#usage>Usage</a> section to jump in.

## Features

* **[Makefile.toplevel-template.mk](Makefile.toplevel-template.mk):** The only file that's not supposed to be use as library/makefile-include, this file contains the suggested template for your top-level project makefile.
* **[Makefile.base.mk](Makefile.base.mk):** Baseline stuff that pretty much all the other Makefile's will require, including colored output for users and assertions on environment variables.  The goal is that this is the only place that should declare Makefile-functions, whereas the rest of these files use make-targets.
* **[Makefile.ansible-vault.mk](Makefile.ansible-vault.mk):** [Ansible vault](https://docs.ansible.com/ansible/2.4/vault.html) workflows (lightweight crypto)
* **[Makefile.ansible.mk](Makefile.ansible.mk):** [Ansible](https://docs.ansible.com/) workflows
* **[Makefile.aws-ecs.mk](#):** [AWS ECS](http://docs.aws.amazon.com/cli/latest/reference/ecs/) workflows
* **[Makefile.bastion.mk](#):** Simple [bastion host](https://en.wikipedia.org/wiki/Bastion_host) workflows, covering things related to ssh, rsync, and Ansible.
* **[Makefile.cloudformation.mk](#):** [Cloudformation](https://aws.amazon.com/cloudformation/) workflows
* **[Makefile.docker.mk](#):** [Docker](https://www.docker.com/) workflows, including some [docker-compose](https://docs.docker.com/compose/) stuff
* **[Makefile.git.mk](#):** Git VCS workflows, mostly the uncommon stuff I can't remember (submodules, sync-from-upstream, etc)
* **[Makefile.json.mk](#):** JSON workflows, mostly with [jq](#).  This includes examples and helpers for various filters/transforms I normally have to look up the syntax of.
* **[Makefile.ssh.mk](#):**  SSH workfows, including keygen, interactive shells, rsync & scp stuff, etc.
* **[Makefile.terraform.mk](#):**  Terraform workflows, especially things that help to access [terraform outputs](#) and pass them to other systems like cloudformation/ansible.

## Design

**Include files: Makefile.*.mk**:  Automation tools in this library are bundled into domain-specific files that should publish discrete, lightweight automation tools.  These are usually designed to be used as [make-includes]([include](https://www.gnu.org/software/make/manual/html_node/Include.html)) in a top-level Makefile.  For example [Makefile.ssh.mk](Makefile.ssh.mk) contains helpers for ssh-related workflows.

**Makefile-Targets:**  Discrete automation workflows are implemented as make-targets, and continuing with the [Makefile.ssh.mk example](Makefile.ssh.mk), would be invoked like `make ssh`.

**Target Parameters:** Following [12-factor principles](https://12factor.net/config) most targets are made parametric by usage of environment variables.  Thus a more realistic invocation of the `ssh` target would be something like this:  `SSH_HOST=host_ip SSH_KEY=/path/to/key.pem SSH_USER=ubuntu SSH_CMD="ls /app" make ssh`

## Usage

### As a Project Automation Library

The usage guide that follows assume your project doesn't already have a top level Makefile.  If you do already have one, you'll want to take a look at the example top-level makefile [here](Makefile.toplevel-template.mk) and figure out how to combine things for the results you want.

We'll also assume you want to set things up so as to potentially track upstream changes in this automation library (or your fork of it) but that's optional.  

Inside your project directory run something like this:

    git submodule add git@github.com:mattvonrocketstein/makefiles.git .makefiles
    git submodule update --init
    cp .makefiles/Makefile.toplevel-template.mk Makefile

Now edit your toplevel Makefile to only include the domain-specific automation stuff that you need.

If you're cloning your project folder later and want to automatically get this `.makefiles` too, you can use `git clone --recursive git://github.com/user/myproject.git` (assuming you have a recent version of git).

### Standalone Usage

Placeholder

## Rationale

This section covers some of the rationale behind an automation library that's (at least partially) based around Makefiles.  Makefile based automation is not my favorite thing, for a variety of reasons.  In particular quoting and variable interpolation is often surprising and code-reuse can be challenging.  

But in a world with Gulpfiles, Rakefiles, Fabfiles, and many other options for project automation, Makefile's feel like a lightweight and mostly dependency-free approach.  It's nice that any Jenkins instance or development environment probably already has `make`.  

Makefiles also have the benefit that they don't commit themselves to any preference for say Python, Ruby or JS at all, which polyglot development shops tend to appreciate.  A further issue is that implementing your core automation library with, for instance, Ruby/Rake would tend to not only couple you to Ruby but to dictate your base version of a Ruby stack.  The only way around this is with extensive use of RVM (or virtualenv in python world), which further complicates CM on your build-servers, etc.
