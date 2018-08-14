class profile::stunnel (
) {

  $stunnel_package = $::osfamily ? {
    'Debian' => 'stunnel4',
    'RedHat' => 'stunnel',
  }

  package { 'stunnel4':
    ensure => installed,
  }

  file { '/etc/systemd/system/stunnel@.service':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/stunnel/stunnel@.service',
  }
  ~> exec { 'reload systemd for stunnel':
    refreshonly => true,
    command     => 'systemctl daemon-reload',
  }

}
