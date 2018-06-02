#!/bin/sh
set -e

mkdir -p /tmp/r10k_boot/{modules,r10k}
puppet module install \
  --target-dir=/tmp/r10k_boot/modules \
  puppet-r10k
puppet module install \
  --target-dir=/tmp/r10k_boot/modules \
  puppetlabs-puppetserver_gem

puppet apply \
  --confdir=/tmp/r10k_boot/r10k \
  --modulepath=/tmp/r10k_boot/modules \
  --hiera_config=/etc/puppetlabs/puppet/hiera.yaml \
  --codedir=/tmp/r10k_boot/r10k \
  configure_r10k.pp
echo "success"
