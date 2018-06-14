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

  $zfs_services = [ 'zfs-import-scan', 'zfs-mount', 'zfs-share', 'zfs-zed',  ]

  service { $zfs_services:
    ensure => running,
    enable => true,
  }

  # TODO; manage firewalld services samba nfs mountd rpc-bind

  ['tcp', 'udp'].each |$p| {
    etcservices::service { "rpc.statd/${p}":
      port    => 662,
      comment => 'nfs rpc.statd',
    }

    etcservices::service { "rpc.mountd/${p}":
      port    => 892,
      comment => 'nfs rpc.mountd',
    }

    etcservices::service { "rpc.lockd/${p}":
      port    => 32768,
      comment => 'nfs rpc.lockd',
    }

    file_line { "lockd ${p} port":
      path  => '/etc/modprobe.d/lockd.conf',
      match => "^(#)?options lockd nlm_${p}port.*$",
      line  => "options lockd nlm_${p}port=32768",
    }

    sysctl { "fs.nfs.nlm_${p}port":
      ensure => present,
      value  => '32768',
      notify => Exec['nfs-server restart'],
    }
  }

  file_line { 'nfs statd port':
    path   => '/etc/sysconfig/nfs',
    match  => '^STATD_PORT=.*$',
    line   => 'STATD_PORT=662',
    notify => Exec['rpc-statd restart'],
  }

  file_line { 'nfs mountd port':
    path   => '/etc/sysconfig/nfs',
    match  => '^MOUNTD_PORT=.*$',
    line   => 'MOUNTD_PORT=892',
    notify => Exec['nfs-server restart'],
  }

}
