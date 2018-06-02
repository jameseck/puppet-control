class profile::base (
  Array $packages = [],
) {

  package { $packages:
    ensure => installed,
  }

  service { 'puppet':
    ensure => running,
    enable => true,
  }

}
