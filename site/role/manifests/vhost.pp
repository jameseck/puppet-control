class role::vhost (
  String[1]                                                 $workgroup   = 'workgroup',
  Array[Struct[{name => String[1], password => String[1]}]] $samba_users = undef,
) {

  class { 'selinux':
    mode => 'enforcing',
    type => 'targeted',
  }

  $shares = [
    '/export/pool1',
    '/export/pool1/films',
    '/export/pool1/music',
    '/export/pool1/origin',
    '/export/pool1/pv',
    '/export/pool1/tv',
  ]

  $shares.each |$s| {
    selinux::fcontext { "set-export-fcontext-${s}":
      ensure   => present,
      pathspec => "${s}(/.*)?",
      seltype  => 'public_content_rw_t',
    }
  }

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
