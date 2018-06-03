class profile::base (
  Array $packages = [],
) {

  include '::ntp'

  package { $packages:
    ensure => installed,
  }

  service { 'puppet':
    ensure => running,
    enable => true,
  }

}
