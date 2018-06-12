class role::openshift (
) {

  include '::profile::epel'

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
    revision => 'release-3.9',
  }

}
