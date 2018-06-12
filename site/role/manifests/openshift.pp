class role::openshift (
  String[1] $release = '3.9',
  Hash      $openshift_users = {},
) {

  include '::profile::epel'
  include '::docker'

  $packages = [
    'git',
    'net-tools',
    'bind-utils',
    'yum-utils',
    'iptables-services',
    'bridge-utils',
    'bash-completion',
    'kexec-tools',
    'sos',
    'psacct',
    ]

  package { $packages:
    ensure => installed,
  }

  $epel_packages = [ 'ansible', 'pyOpenSSL', ]

  package { $epel_packages:
    ensure          => installed,
    install_options => '--enablerepo=epel',
    require         => Class['profile::epel'],
  }

  vcsrepo { '/opt/openshift-ansible':
    ensure   => present,
    provider => 'git',
    source   => 'https://github.com/openshift/openshift-ansible',
    revision => "release-${release}",
  }

  $openshift_users.each |$k, $v|  {
    httpauth { $k:
      ensure    => present,
      file      => '/etc/origin_htpasswd_source',
      password  => $v,
      realm     => 'realm',
      mechanism => 'basic',
    }
  }

  # parameterise ansible inventory file
  # deal with pv's for metrics, logging, registry, etc


}
