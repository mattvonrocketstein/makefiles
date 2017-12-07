## About

I'm honestly the type of person who never thought they would have a `makefiles` repository, but here it is.  

## Rationale

This section covers some of the rationale.. jump straight to the [Usage Section](#usage) if you don't care!

Makefile based automation is not my favorite thing, for a variety of reasons.  In particular quoting and variable interpolation is often surprising and code-reuse can be challenging.  

But in a world with Gulpfiles, Rakefiles, Fabfiles, and many other options for project automation, Makefile's feel like a lightweight and mostly dependency-free approach.  It's nice that any Jenkins instance or development environment probably already has `make`.  

Makefiles also have the benefit that they don't commit itself to any preference for say Python, Ruby or JS at all, and much less a specific version of any of the above, so polyglot development shops tend to appreciate that

## Design Overview

**Include files: Makefile.*.mk**:  Lightweight, highly specific automation tools are bundled into domain-specific files like [Makefile.ssh.mk](Makefile.ssh.mk), and these files are intended to be used as [make-includes]([include](https://www.gnu.org/software/make/manual/html_node/Include.html)) in a top-level Makefile.  

**Generic Targets:**  Individual automation tools are implemented as make-targets, and invoked like `make ssh`.  

**Target Parameters:** Following [12-factor principles](https://12factor.net/config) most targets are made parametric by usage of environment variables.  Thus a more realistic invocation of the `ssh` target would be something like this:  `SSH_HOST=host_ip SSH_KEY=/path/to/key.pem SSH_USER=ubuntu SSH_CMD="ls /app" make ssh`

## Usage

The usage guide that follows assume your project doesn't already have a top level Makefile.  If you do already have one, you'll want to take a look at the example top-level makefile [here](Makefile.toplevel-template.mk) and figure out how to combine things for the results you want.

We'll also assume you want to set things up so as to potentially track upstream changes in this automation library (or your fork of it) but that's optional.  As a library, this repo and it's license are such that you can chop it up and remix it, so feel free to use any hacky copy/paste/modify workflow that makes you happy.
