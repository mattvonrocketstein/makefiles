## Makefile.packer.mk

## Example Usage


**Your average workflow** for render, key-up, build, and describe artifacts looks like what you see below.

```
# by default, converts `packer/build_ami.yml` to `packer/build_ami.json`
make packer-render

# drops packer.pem from AWS SSM path into `./packer.pem`
PACKER_KEY_SSM_PATH=/path/to/ssh-key make packer-get-key

# by default, runs `packer build` with the given
# dockerized packer, using `packer/build_ami.json`
PACKER_IMAGE=hashicorp/packer make packer-build

# by default, grabs AMI ID from output in manifest.json
make packer-get-ami
```
