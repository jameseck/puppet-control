class profile::base (
) {

  $fam = $facts['os']['family']

  $packages = lookup("packages_${downcase($fam)}")

  package { $packages:
    ensure => installed,
  }

}
