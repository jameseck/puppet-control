class role::vhost (
  String[1]                                                      $workgroup   = 'workgroup',
  Array[Struct[{user_name => String[1], password => String[1]}]] $samba_users = undef,
) {

  class { 'samba::server':
    workgroup     => $workgroup,
    server_string => $facts['fqdn'],
    interfaces    => 'lo br0',
    security      => 'user'
  }

  notify { 'samba_users':
    message => $samba_users,
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
#    create_mask          => 0644,
#    force_create_mask    => 0644,
#    directory_mask       => 0755,
#    force_directory_mask => 0755,
#    force_group          => 'james',
#    force_user           => 'james',
#    copy                 => 'some-other-share',
  }

}
