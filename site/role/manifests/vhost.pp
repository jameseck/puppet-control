class role::vhost (
  String[1]                                                 $workgroup   = 'workgroup',
  Array[Struct[{name => String[1], password => String[1]}]] $samba_users = undef,
) {

  class { 'samba::server':
    workgroup     => $workgroup,
    server_string => $facts['fqdn'],
    interfaces    => 'lo br0',
    security      => 'user'
  }

  $samba_users.each |$u| {
    samba::server::user { $u['name']:
      password  => $u['password'],
    }
  }

  samba::server::share { 'pool1':
    comment       => 'pool1',
    path          => '/export/pool1',
    guest_only    => false,
    guest_ok      => false,
    guest_account => '',
    browsable     => true,
    read_only     => false,
#    force_group   => 'root',
#    force_user    => 'root',
    valid_users   => 'james',
#    create_mask          => 0644,
#    force_create_mask    => 0644,
#    directory_mask       => 0755,
#    force_directory_mask => 0755,
#    copy                 => 'some-other-share',
  }

}
