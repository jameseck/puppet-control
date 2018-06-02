class { 'r10k':
  remote          => 'https://github.com/jameseck/puppet-control.git',
  provider        => 'puppet_gem',
  deploy_settings => {
    'purge_levels' => [ 'deployment', 'environment', 'puppetfile' ],
  }
}
