#!/bin/sh
set -e

mkdir -p /tmp/r10k_boot/{modules,r10k}
touch /tmp/r10k_boot/r10k/hiera.yaml
puppet module install \
  --target-dir=/tmp/r10k_boot/modules
  puppet-r10k

puppet apply \
  --confdir=/tmp/r10k_boot/r10k \
  --modulepath=/tmp/r10k_boot/modules \
  --hiera_config=/tmp/r10k_boot/r10k/hiera.yaml \
  --codedir=/tmp/r10k_boot/r10k \
  configure_r10k.pp
echo "success"
