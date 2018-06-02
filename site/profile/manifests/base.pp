class profile::base (
) {

  $fam = downcase(facts['os']['family'])
  $packages = lookup("packages_${fam}")

  package { $packages:
    ensure => installed,
  }

}
