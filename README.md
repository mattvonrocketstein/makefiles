## About

I'm honestly the type of person who never thought they would have a `makefiles` repository.

## Usage

```

# change into the project directory where you want to install makefiles
mkdir -p my-project; cd my-project

# Set this to something different if you want to use your own fork
export MAKEFILES_REPO=https://github.com/mattvonrocketstein/makefiles.git  

# Grab the demo/template Makefile
git archive --remote=$MAKEFILES_REPO HEAD:Makefile Makefile | tar -x

$ git clone --depth=1 $MAKEFILES_REPO

```
