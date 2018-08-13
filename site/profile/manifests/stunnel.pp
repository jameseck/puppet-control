class profile::stunnel (
) {

  package { 'stunnel':
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
