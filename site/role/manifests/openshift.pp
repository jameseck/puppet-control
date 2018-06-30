class role::openshift (
  String[1] $release         = '3.9',
  Hash      $openshift_users = {},
  String[1] $openshift_master_default_subdomain = 'apps.letitbleed.org',
  String[1] $openshift_master_cluster_hostname  = 'openshift.letitbleed.org',
  String[1] $openshift_hosted_storage_root_dir  = '/export/openshift',
) {

  include '::profile::epel'
  #include '::docker'
  include '::nfs::server'

  $hosted_storage_paths = [
    "${openshift_hosted_storage_root_dir}/registry",
    "${openshift_hosted_storage_root_dir}/logging",
    "${openshift_hosted_storage_root_dir}/metrics",
  ]

  exec { "mkdir -p ${openshift_hosted_storage_root_dir}":
    creates => $openshift_hosted_storage_root_dir,
  }
  -> file { [ $openshift_hosted_storage_root_dir, $hosted_storage_paths, ]:
    ensure => directory,
    owner  => 1000040000,
    group  => 1000040000,
    mode   => '0775',
  }

  $hosted_storage_prometheus_paths = [
    "${openshift_hosted_storage_root_dir}/prometheus",
    "${openshift_hosted_storage_root_dir}/prometheus-alertmanager",
    "${openshift_hosted_storage_root_dir}/prometheus-alertbuffer",
  ]
  -> file { [ $hosted_storage_prometheus_paths, ]:
    ensure => directory,
    owner  => 1000090000,
    group  => 1000090000,
    mode   => '0775',
  }

  [ $hosted_storage_paths, $hosted_storage_prometheus_paths, ].flatten.each |$p| {
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
    'python-passlib',
    'java-1.8.0-openjdk-headless',
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
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('role/openshift/ansible_inventory.erb'),
  }

  # TODO: disable firewalld and set up iptables rules
  # Openshift installer does some of this so we need to tread carefully

  exec { 'Run the Openshift prerequisites ansible playbook':
    command => 'ansible-playbook -i /opt/openshift/inventory/hosts /opt/openshift-ansible/playbooks/prerequisites.yml && touch /opt/openshift/prerequisites_run',
    creates => '/opt/openshift/prerequisites_run',
  }
  -> exec { 'Run the Openshift deploy-cluster playbook':
    command => 'ansible-playbook -i /opt/openshift/inventory/hosts /opt/openshift-ansible/playbooks/deploy_cluster.yml',
    creates => '/opt/openshift/deploycluster_run',
  }

  # TODO: fix permissions issue for logging/metrics pods - user 1000040000 needs access to create dirs on nfs path,
  # but we can't predict what uid will be assigned...perhaps

}
