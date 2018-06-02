#!/bin/sh
set -e

mkdir -p /tmp/r10k_boot/modules
puppet module install puppet-r10k --target-dir=/tmp/r10k_boot/modules
puppet apply --modulepath=/tmp/r10k_boot/modules configure_r10k.pp
echo "success"
