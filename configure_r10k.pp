package { 'hiera-eyaml-puppet':
  ensure   => installed,
  name     => 'hiera-eyaml',
  provider => 'puppet_gem',
}
package { 'hiera-eyaml-puppetserver':
  ensure   => installed,
  name     => 'hiera-eyaml',
  provider => 'puppetserver_gem',
}
class { 'r10k':
  remote          => 'https://github.com/jameseck/puppet-control.git',
  provider        => 'puppet_gem',
  deploy_settings => {
    'purge_levels' => [ 'deployment', 'environment', 'puppetfile' ],
  }
}
