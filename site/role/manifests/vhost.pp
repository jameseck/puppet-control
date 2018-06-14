class role::vhost (
  String[1] $workgroup = 'jehome',
  Variant[Struct[{user_name => String[1], password => String[1]}], Undef ] $users = undef,
) {

  class { 'samba::server':
    workgroup     => $workgroup,
    server_string => $facts['fqdn'],
    interfaces    => 'lo br0',
    security      => 'user'
  }

  $users.each |$k,$v| {
    samba::server::user { $k:
      user_name => $v['user_name'],
      password  => $v['password'],
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
