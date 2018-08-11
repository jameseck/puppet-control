class profile::base (
  Array $packages = [],
) {

  include '::ntp'
  include '::ssh'

  if ( $facts['osfamily'] == 'RedHat' ) {
    include '::profile::epel'
  }

  if $facts['virtual'] == 'kvm' {
    include '::profile::kvm'
  }

  package { $packages:
    ensure => installed,
  }

  if versioncmp($::puppetversion, '5.0.0') >= 0 {
    $puppet_conf_file = '/etc/puppetlabs/puppet/puppet.conf'
  } else {
    $puppet_conf_file = '/etc/puppet/puppet.conf'b
  }


  [ 'agent', 'master'].each |$section| {
    ini_setting { "remove server from ${section}":
      ensure  => absent,
      path    => $puppet_conf_file,
      section => $section,
      setting => 'server',
      notify  => Service['puppet'],
    }
  }
  ini_setting { 'server':
    ensure  => present,
    path    => $puppet_conf_file,
    section => 'main',
    setting => 'server',
    value   => $::puppetserver,
    notify  => Service['puppet'],
  }

  service { 'puppet':
    ensure => running,
    enable => true,
  }

  user { 'pi':
    ensure => absent,
  }
  -> group { 'pi':
    ensure => absent,
  }
  -> group { 'james':
    ensure => present,
    gid    => '1000',
  }
  user { 'james':
    ensure     => present,
    uid        => '1000',
    gid        => '1000',
    home       => '/home/james',
    managehome => true,
    password   => lookup('james_user_password'),
  }

  user { 'root':
    password => lookup('root_user_password'),
  }

  ssh_authorized_key { 'james - james.eckersall@jameseck-laptop.glo.gb':
    ensure => present,
    user   => 'james',
    type   => 'ssh-rsa',
    key    => lookup('james_user_ssh_pub_key'),
  }

  ssh_authorized_key { 'root - james.eckersall@jameseck-laptop.glo.gb':
    ensure => present,
    user   => 'root',
    type   => 'ssh-rsa',
    key    => lookup('james_user_ssh_pub_key'),
  }

}
