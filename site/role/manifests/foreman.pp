class role::foreman (
) {

  class { 'r10k':
    remote => 'https://www.github.com:jameseck/puppet-control.git',
  }

  class {'r10k::webhook':
    require => Class['r10k::webhook::config'],
  }

  class { 'r10k::webhook::config':
    use_mcollective => false,
  }

}
