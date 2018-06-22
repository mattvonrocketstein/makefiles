## Makefile.sceptre.mk

## Usage

**Describe stack deployments in all environments:**

```
make sceptre-describe-envs
```

**Create stack:**

```
env=prod stack=appserver make sceptre-launch-stack

# or a shortened version:

env=prod stack=appserver make sls
```


**Describe stack:**

```
env=ssm stack=appserver make sceptre-describe-stack

# or a shortened version:

env=prod stack=appserver make sds
```

**Update stack :**

```
env=prod stack=appserver make sceptre-launch-stack

# or a shortened version

env=prod stack=appserver make sls
```

**Delete a stack:**

```
env=test stack=appserver make sceptre-delete-stack
```
