class role::foreman (
) {

  class { 'r10k':
    remote          => 'https://github.com/jameseck/puppet-control.git',
    r10k_basedir    => '/etc/puppetlabs/code/environments',
    provider        => 'puppet_gem',
    deploy_settings => {
      'purge_levels' => [ 'deployment', 'environment', 'puppetfile' ],
    }
  }

  class {'r10k::webhook':
    require => Class['r10k::webhook::config'],
  }

  class { 'r10k::webhook::config':
    use_mcollective => false,
  }

  package { 'hiera-eyaml-puppet':
    ensure   => installed,
    name     => 'hiera-eyaml',
    provider => 'puppet_gem',
  }
  package { 'hiera-eyaml-puppetserver':
    ensure   => installed,
    name     => 'hiera-eyaml',
    provider => 'puppetserver_gem',
    notify   => Service['puppetserver'],
  }
  service { 'puppetserver':
    ensure => running,
  }
}
