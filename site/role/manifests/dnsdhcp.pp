class role::dnsdhcp (
  Hash $dns_records = {},
) {

  $dns_master_ip = '192.168.1.151'
  $dns_slave_ip  = '192.168.1.168'

  include '::keepalived'

  $packages = [ 'dnsutils', 'ntpdate', ]
  package { $packages:
    ensure => installed,
  }

  class { 'ntp':
  }


  file { '/etc/keepalived/notify-keepalived.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('role/dnsdhcp/notify-keepalived.sh.erb'),
    notify  => Class['keepalived::service'],
  }

  file { '/etc/keepalived/check-keepalived.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('role/dnsdhcp/check-keepalived.sh.erb'),
    notify  => Class['keepalived::service'],
  }

  keepalived::vrrp::instance { 'VI_DNS':
    interface         => 'eth0',
    state             => 'MASTER',
    virtual_router_id => '51',
    priority          => '101',
    auth_type         => 'PASS',
    auth_pass         => 'secret',
    virtual_ipaddress => [ '192.168.1.9/24' ],
    notify_script     => '/etc/keepalived/notify-keepalived.sh',
    track_script      => 'checkscript',
  }
  -> keepalived::vrrp::script { 'checkscript':
    script   => '/etc/keepalived/check-keepalived.sh',
    interval => 2,
    rise     => 2,
    fall     => 2,
    weight   => 2,
  }



########################################################################################################################
  file { '/etc/bind/zones.rfc1912':
    ensure  => file,
    content => '',
    notify  => Class['dns'],
  }

  class { 'dns':
    defaultzonepath => 'unmanaged',
  }

  $dns_masters = $facts['ipaddress'] ? {
    $dns_master_ip => [],
    default        => [ $dns_master_ip, ],
  }

  dns::zone { 'je.home':
    allow_transfer => [ 'localhost', $dns_master_ip, $dns_slave_ip, ],
    also_notify    => [ $dns_master_ip, $dns_slave_ip, ],
    masters        => $dns_masters,
  }

  dns::zone { '1.168.192.in-addr.arpa':
    allow_transfer => [ 'localhost', $dns_master_ip, $dns_slave_ip, ],
    also_notify    => [ $dns_master_ip, $dns_slave_ip, ],
    masters        => $dns_masters,
    reverse        => true,
  }

  Dns_record {
    provider => bind,
    ddns_key => '/etc/bind/rndc.key',
    server   => 'localhost',
    ttl      => '3200',
    domain   => 'je.home',
  }

  create_resources('dns_record', $dns_records)

########################################################################################################################

  class { 'dhcp':
    dnsdomain    => [
      'je.home',
      '1.168.192.in-addr.arpa',
    ],
    nameservers  => ['192.168.1.2'],
    ntpservers   => ['uk.pool.ntp.org'],
    interfaces   => ['eth0'],
    dnsupdatekey => '/etc/bind/rndc.key',
    dnskeyname   => 'rndc-key',
    require      => Class['dns'],
    pxeserver    => $facts['ipaddress'],
    pxefilename  => 'pxelinux.0',
    omapi_name   => 'omapi-key',
    omapi_key    => 'CMxsdCRaTT3BsMV1F1XaVW7+1iuxwsRKCtTfYgAXKc2XphcC/aOS5RePO/kLGyDiJ2yKbTqYXhIUy4sQkq70Og==',
  }

  dhcp::pool { 'je.home':
    network  => '192.168.1.0',
    mask     => '255.255.255.0',
    range    => ['192.168.1.150 192.168.1.169',],
    gateway  => '192.168.1.1',
    failover => 'dhcp-failover',
  }

  class { 'dhcp::failover':
    role         => primary,
    port         => 647,
    peer_address => '192.168.1.7',
    omapi_key    => 'omapi-key',
  }

  $dhcp_hosts = {
    'fedoradesk.je.home' => {
      mac => '08:00:27:c0:42:2a',
      ip  => '192.168.1.101',
    },
    'openstack-kvm.je.home' => {
      mac => 'bc:5f:f4:fe:e7:fc',
      ip  => '192.168.1.230',
    },
    'foreman.je.home' => {
      mac => '52:54:00:95:86:e4',
      ip  => '192.168.1.2',
    },
    'kvm.je.home' => {
      mac => '00:19:bb:d2:34:14' ,
      ip  => '192.168.1.30',
    },
    'laptopw.je.home' => {
      mac => '90:61:ae:5e:e9:2b',
      ip  => '192.168.1.49',
    },
    'laptop.je.home' => {
      mac => '54:e1:ad:96:4c:8c',
      ip  => '192.168.1.50',
    },
    'origin.je.home' => {
      mac => '52:54:00:18:30:47',
      ip  => '192.168.1.6',
    },
    'erx.je.home' => {
      mac => 'b8:27:eb:c2:11:56',
      ip  => '192.168.1.1',
    },
    'rpi.je.home' => {
      mac => 'b8:27:eb:35:2f:64',
      ip  => '192.168.1.222',
    },
    'magnum.je.home' => {
      mac => '1c:1b:0d:eb:d0:02',
      ip  => '192.168.1.40',
    },
    'unifiap.je.home' => {
      mac => 'f0:9f:c2:f3:ca:2f',
      ip  => '192.168.1.39',
    },
    'kvm-eric.je.home' => {
      mac => 'fe:00:00:49:07:d9',
      ip  => '192.168.1.210',
    },
    'tplinksw.je.home' => {
      mac => 'e8:de:27:41:af:bf',
      ip  => '192.168.1.249',
    },
    'dnsdhcp01.je.home' => {
      mac => 'b8:27:eb:c2:11:56',
      ip  => '',
    },
  }

  create_resources('dhcp::host', $dhcp_hosts)

  #00:1b:38:fa:48:01	bmw laptop wired
  #00:1f:3a:3c:28:03	bmw laptop wireless
  #00:05:cd:5b:0e:bf	denon ?? maybe
  #94:65:2d:d2:3a:d3	OnePlus 5T
  #00:07:f5:22:33:3b	Sony STR-DN1020
  #b8:27:eb:81:65:2e	raspberrypi3.je.home
  #c0:4a:00:6c:fd:e2 	dlink.je.home

}
