class profile::epel (
  Boolean $enabled = true,
) {

  package { 'epel-release':
    ensure => installed,
  }

  $enab = $enabled ? {
    true  => 1,
    false => 0,
  }

  ini_setting { "epel enabled=${enabled}":
    ensure  => present,
    path    => '/etc/yum.repos.d/epel.repo',
    section => 'epel',
    setting => 'enabled',
    value   => $enab,
  }

}
