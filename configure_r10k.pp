package { 'hiera-eyaml':
  ensure   => installed,
  provider => 'puppet_gem',
}
package { 'hiera-eyaml':
  ensure   => installed,
  provider => 'puppetserver_gem',
}
class { 'r10k':
  remote          => 'https://github.com/jameseck/puppet-control.git',
  provider        => 'puppet_gem',
  deploy_settings => {
    'purge_levels' => [ 'deployment', 'environment', 'puppetfile' ],
  }
}
