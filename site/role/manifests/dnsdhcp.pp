class role::dnsdhcp (
  Hash                $hosts   = {},
  Stdlib::IP::Address $checkip = $facts['ipaddress'], # The IP that is used by the Keepalived healthcheck script (DNS query)
) {

  $dns_master_ip  = '192.168.1.7'
  $dns_slave_ip   = '192.168.1.8'
  $dns_vip_ip     = '192.168.1.9'
  $dns_vip_subnet = '24'

  include '::keepalived'
  include '::foreman_proxy'

  package { 'libipset3':
    ensure => installed,
  }
  -> Class['keepalived']

#  $packages = [ 'dnsutils', 'ntpdate', ]
#  package { $packages:
#    ensure => installed,
#  }


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
    virtual_ipaddress => [ "${dns_vip_ip}/${dns_vip_subnet}" ],
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

#  class { 'dns':
#    defaultzonepath => 'unmanaged',
#  }

  $dns_masters = $facts['ipaddress'] ? {
    $dns_master_ip => [],
    default        => [ $dns_master_ip, ],
  }

  Dns::Zone<| title == 'je.home' |> {
    allow_transfer => [ 'localhost', $dns_master_ip, $dns_slave_ip, ],
    also_notify    => [ $dns_master_ip, $dns_slave_ip, ],
    masters        => $dns_masters,
  }
#  dns::zone { 'je.home':
#    allow_transfer => [ 'localhost', $dns_master_ip, $dns_slave_ip, ],
#    also_notify    => [ $dns_master_ip, $dns_slave_ip, ],
#    masters        => $dns_masters,
#  }

  #dns::zone { '1.168.192.in-addr.arpa':
  Dns::Zone<| title == '1.168.192.in-addr.arpa' |> {
    allow_transfer => [ 'localhost', $dns_master_ip, $dns_slave_ip, ],
    also_notify    => [ $dns_master_ip, $dns_slave_ip, ],
    masters        => $dns_masters,
    reverse        => true,
  }

  #create_resources('dns_record', $hosts)

########################################################################################################################

#  class { 'dhcp':
#    dnsdomain    => [
#      'je.home',
#      '1.168.192.in-addr.arpa',
#    ],
#    nameservers  => ['192.168.1.2'],
#    ntpservers   => ['uk.pool.ntp.org'],
#    interfaces   => ['eth0'],
#    dnsupdatekey => '/etc/bind/rndc.key',
#    dnskeyname   => 'rndc-key',
#    require      => Class['dns'],
#    pxeserver    => $facts['ipaddress'],
#    pxefilename  => 'pxelinux.0',
#    omapi_name   => 'omapi-key',
#    omapi_key    => 'CMxsdCRaTT3BsMV1F1XaVW7+1iuxwsRKCtTfYgAXKc2XphcC/aOS5RePO/kLGyDiJ2yKbTqYXhIUy4sQkq70Og==',
#  }



#  dhcp::pool { 'je.home':
#    network  => '192.168.1.0',
#    mask     => '255.255.255.0',
#    range    => ['192.168.1.150 192.168.1.169',],
#    gateway  => '192.168.1.1',
#    failover => 'dhcp-failover',
#  }

#  class { 'dhcp::failover':
#    role         => primary,
#    port         => 647,
#    peer_address => '192.168.1.7',
#    omapi_key    => 'omapi-key',
#  }

  Dns_record {
    provider => bind,
    ddns_key => '/etc/bind/rndc.key',
    server   => 'localhost',
    ttl      => '3200',
    domain   => 'je.home',
  }

  $hosts.each |$k, $v| {
    dns_record { $k:
      type    => 'A',
      content => $v['ip'],
    }
    if ($v['mac'] =~ Dhcp::Macaddress) {
      dhcp::host { $k:
        ip  => $v['ip'],
        mac => $v['mac'],
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

#  class{'::foreman_proxy':
#    puppet        => true,
#    puppetca      => true,
#    tftp          => false,
#    dhcp          => true,
#    dhcp_provider => 'isc',
#    dns           => false,
#    bmc           => false,
#    realm         => false,
#  }


}
