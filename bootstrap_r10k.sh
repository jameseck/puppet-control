#!/bin/sh
set -e

mkdir -p /tmp/r10k_boot/{modules,r10k}
touch /tmp/r10k_boot/r10k/hiera.yaml
puppet module install puppet-r10k --target-dir=/tmp/r10k_boot/modules
puppet apply --confdir=/tmp/r10k_boot/r10k --modulepath=/tmp/r10k_boot/modules --hiera_config=/tmp/r10k_boot/r10k/hiera.yaml configure_
r10k.pp  --codedir=/tmp/r10k_boot/r10k
echo "success"
