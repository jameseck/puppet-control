class role::vhost (
  String[1] $workgroup    = 'workgroup',
  Array[
    Struct[{
      name     => String[1],
      password => String[1],
    }]]     $samba_users  = undef,
  Array     $samba_shares = [],
) {

  include '::docker'
  include '::nfs::server'

  $exports = [
    'pool1',
    'pool1/films',
    'pool1/music',
    'pool1/tv',
    'pool1/pv',
    'pool2',
  ]

  $exports.each |$ex| {
    nfs::server::export {"export ${ex}":
      path    => "/export/${ex}",
      clients => ['*', ],
      options => 'rw,sync,wdelay,hide,crossmnt,no_subtree_check,mountpoint,sec=sys,secure,no_root_squash,no_all_squash',
    }
  }

  selboolean { 'samba_export_all_rw':
    persistent => true,
    value      => 'on',
  }

  class { 'selinux':
    mode => 'enforcing',
    type => 'targeted',
  }

  package { 'dejavu-lgc-sans-fonts':
    ensure => installed,
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

  [ 'pool1', 'pool2', ].each |$p| {
    samba::server::share { $p:
      comment       => $p,
      path          => "/export/${p}",
      guest_only    => false,
      guest_ok      => false,
      guest_account => '',
      browsable     => true,
      read_only     => false,
      force_group   => 'root',
      valid_users   => 'james',
    }
  }

  $zfs_services = [ 'zfs-mount', 'zfs-share', 'zfs-zed', ] #'zfs-import-scan', 

  service { $zfs_services:
    ensure => running,
    enable => true,
  }

  # TODO; manage firewalld services samba nfs mountd rpc-bind

#  ['tcp', 'udp'].each |$p| {
#    etcservices::service { "rpc.statd/${p}":
#      port    => 662,
#      comment => 'nfs rpc.statd',
#    }

#    etcservices::service { "rpc.mountd/${p}":
#      port    => 892,
#      comment => 'nfs rpc.mountd',
#    }

#    etcservices::service { "rpc.lockd/${p}":
#      port    => 32768,
#      comment => 'nfs rpc.lockd',
#    }

#    file_line { "lockd ${p} port":
#      path  => '/etc/modprobe.d/lockd.conf',
#      match => "^(#)?options lockd nlm_${p}port.*$",
#      line  => "options lockd nlm_${p}port=32768",
#    }

#    sysctl { "fs.nfs.nlm_${p}port":
#      ensure => present,
#      value  => '32768',
#      notify => Exec['nfs-server restart'],
#    }
#  }

#  file_line { 'nfs statd port':
#    path   => '/etc/sysconfig/nfs',
#    match  => '^STATD_PORT=.*$',
#    line   => 'STATD_PORT=662',
#    notify => Exec['rpc-statd restart'],
#  }

#  file_line { 'nfs mountd port':
#    path   => '/etc/sysconfig/nfs',
#    match  => '^MOUNTD_PORT=.*$',
#    line   => 'MOUNTD_PORT=892',
#    notify => Exec['nfs-server restart'],
#  }

#  exec { 'nfs-server restart':
#    command     => 'systemctl restart nfs-server',
#    refreshonly => true,
#    notify      => Exec['zfs-share restart'],
#  }

#  exec { 'zfs-share restart':
#    command     => 'systemctl restart zfs-share',
#    refreshonly => true,
#  }

#  exec { 'rpc-statd restart':
#    command     => 'systemctl restart rpc-statd',
#    refreshonly => true,
#  }
}
