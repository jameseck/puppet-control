## site.pp ##

# This file (/etc/puppetlabs/puppet/manifests/site.pp) is the main entry point
# used when an agent connects to a master and asks for an updated configuration.
#
# Global objects like filebuckets and resource defaults should go in this file,
# as should the default node definition. (The default node can be omitted
# if you use the console and don't define any other nodes in site.pp. See
# http://docs.puppetlabs.com/guides/language_guide.html#nodes for more on
# node definitions.)

## Active Configurations ##

# PRIMARY FILEBUCKET
# This configures puppet agent and puppet inspect to back up file contents when
# they run. The Puppet Enterprise console needs this to display file contents
# and differences.

# Define filebucket 'main':
filebucket { 'main':
  server => 'puppet',
  path   => false,
}

# Make filebucket 'main' the default backup location for all File resources:
File { backup => 'main' }

Exec { path => '/usr/sbin:/usr/bin:/sbin:/bin' }

$allow_virtual_packages = hiera('allow_virtual_packages',false)
Package {
  allow_virtual => $allow_virtual_packages,
}

# Checking if any trusted facts are defined in the cert, if not we disable this check for now
# to allow backwards compatibility
if !is_hash($trusted) {

  crit('Trusted fact support MUST be turned on the server for any Puppet Catalogs to be served')

} else {
  if defined('$role') {
    fail("The servers role can NOT be overridden, it should always be defined by trusted facts (Role Assigned ${role})")
  }

  $role = $trusted['extensions']['pp_role']

  # The $certname fact is self-reported by the node to we cannot trust it :-(
  # https://docs.puppetlabs.com/puppet/latest/reference/lang_facts_and_builtin_vars.html#puppet-agent-facts
  $trusted_certname = $trusted['certname']
}

include '::profile::base'

node default {
  #We use the Trusted Cert Role to instantiate the VM by default.
  if ( $::role != '') {
    include "role::${::role}"
  }
}
