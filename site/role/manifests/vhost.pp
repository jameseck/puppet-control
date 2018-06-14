class role::vhost (
  String[1] $workgroup    = 'workgroup',
  Array[
    Struct[{
      name     => String[1],
      password => String[1],
    }]]     $samba_users  = undef,
  Array     $samba_shares = [],
) {

  class { 'selinux':
    mode => 'enforcing',
    type => 'targeted',
  }


  $samba_shares.each |$s| {
    selinux::fcontext { "set-export-fcontext-${s}":
      ensure   => present,
      pathspec => "${s}(/.*)?",
      seltype  => 'public_content_rw_t',
    }
    ~> selinux::exec_restorecon { "restorecon-for-${s}":
      path        => $s,
      recurse     => true,
      refreshonly => true,
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
    force_group   => 'root',
    valid_users   => 'james',
  }

}
