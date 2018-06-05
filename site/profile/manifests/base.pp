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

  group { 'james':
    ensure => present,
    gid    => '1000',
  }
  user { 'james':
    ensure   => present,
    uid      => '1000',
    gid      => '1000',
    password => lookup('james_user_password'),
  }

  ssh_authorized_key { 'james':
    ensure => present,
    user   => 'james',
    type   => 'ssh-rsa',
    key    => lookup('james_user_ssh_pub_key'),
  }

}
