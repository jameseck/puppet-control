#!/bin/sh
set -e

mkdir -p /tmp/r10k_boot/{modules,r10k}

MODULES="puppet-r10k puppetlabs/stdlib puppetlabs/ruby puppetlabs/gcc puppet/make puppetlabs/inifile puppetlabs/vcsrepo puppetlabs/git gentoo/portage puppetlabs-puppetserver_gem"

for m in $MODULES; do
  puppet module install \
    --target-dir=/tmp/r10k_boot/modules \
    --modulepath=/tmp/r10k_boot/modules \
    $m
done

puppet apply \
  --confdir=/tmp/r10k_boot/r10k \
  --modulepath=/tmp/r10k_boot/modules \
  --hiera_config=/etc/puppetlabs/puppet/hiera.yaml \
  --codedir=/tmp/r10k_boot/r10k \
  configure_r10k.pp

echo "success"
~

