class profile::base (
) {

  $packages = lookup("packages_${downcase($facts['os']['family'])}")

  package { $packages:
    ensure => installed,
  }

}
