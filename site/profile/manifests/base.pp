class profile::base (
  Array $packages = [],
) {

  package { $packages:
    ensure => installed,
  }

}
