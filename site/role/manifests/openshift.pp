class role::openshift (
  String[1] $release         = '3.9',
  Hash      $openshift_users = {},
  String[1] $openshift_master_default_subdomain = 'apps.letitbleed.org',
  String[1] $openshift_master_cluster_hostname  = 'openshift.letitbleed.org',
  String[1] $openshift_hosted_storage_root_dir  = '/export/openshift',
) {

  include '::profile::epel'
  include '::docker'
  include '::nfs::server'

  $hosted_storage_paths = [
    "${openshift_hosted_storage_root_dir}/registry",
    "${openshift_hosted_storage_root_dir}/logging",
    "${openshift_hosted_storage_root_dir}/metrics",
    "${openshift_hosted_storage_root_dir}/prometheus",
    "${openshift_hosted_storage_root_dir}/prometheus_alertmanager",
    "${openshift_hosted_storage_root_dir}/prometheus_alertbuffer",
  ]

  exec { "mkdir -p ${openshift_hosted_storage_root_dir}":
    creates => $openshift_hosted_storage_root_dir,
  }
  -> file { [ $openshift_hosted_storage_root_dir, $hosted_storage_paths, ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  $hosted_storage_paths.each |$p| {
    nfs::server::export { "nfs export for ${p}":
      path    => $p,
      clients => [ $facts['fqdn'], ],
      options => 'rw,no_root_squash',
      comment => 'Created by role::openshift',
    }
  }

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

  vcsrepo { '/opt/openshift/ansible':
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

  # Generate self-signed SSL for initial bootstrapping
  $base_path = '/opt/openshift'
  $cert_file = "${base_path}/certs/${openshift_master_cluster_hostname}.crt"
  $key_file  = "${base_path}/certs/${openshift_master_cluster_hostname}.key"

  file { [ $base_path, "${base_path}/certs", "${base_path}/inventory" ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }
  -> openssl::certificate::x509 { $openshift_master_cluster_hostname:
    country      => 'UK',
    organization => 'JE',
    commonname   => $openshift_master_cluster_hostname,
    base_dir     => "${base_path}/certs",
  }

  # parameterise ansible inventory file
  # deal with pv's for metrics, logging, registry, etc
  $openshift_master_named_certificates = [{ 'certfile' => $cert_file, 'keyfile' => $key_file, 'cafile' => $cert_file }]

  $openshift_named_certs_erb = inline_template("<% require 'json' -%><%= @openshift_master_named_certificates.to_json -%>")

  file { "${base_path}/inventory/hosts":
    ensure   => file,
    owner    => 'root',
    group    => 'root',
    mode     => '0644',
    template => template('roles/openshift/ansible_inventory.erb'),
  }

}
