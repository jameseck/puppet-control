class role::dnsdhcp (
  Hash $hosts = {},
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

  #create_resources('dns_record', $hosts)

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

  $hosts.each |$h| {
    dns_record { $h[0]:
      type    => 'A',
      content => $h[1]['ip'],
    }
    if (is_mac_address($h[1]['mac'])) {
      dhcp::host { $h[0]:
        ip  => $h[1]['ip'],
        mac => $h[1]['mac'],
      }
    }
  }
  #create_resources('dhcp::host', $dhcp_hosts)

  #00:1b:38:fa:48:01	bmw laptop wired
  #00:1f:3a:3c:28:03	bmw laptop wireless
  #00:05:cd:5b:0e:bf	denon ?? maybe
  #94:65:2d:d2:3a:d3	OnePlus 5T
  #00:07:f5:22:33:3b	Sony STR-DN1020
  #b8:27:eb:81:65:2e	raspberrypi3.je.home
  #c0:4a:00:6c:fd:e2 	dlink.je.home

}
