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
    source => 'puppet:///profiles/stunnel/stunnel@.service',
  }

}
