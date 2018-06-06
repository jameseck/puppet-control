class role::dnsdhcp (
  Hash                $hosts          = {},
  Stdlib::IP::Address $checkip        = $facts['ipaddress'], # The IP that is used by the Keepalived healthcheck script (DNS query)
  String              $dns_zone_fwd   = 'je.home',
  String              $dns_zone_rev   = '1.168.192.in-addr.arpa',
  Stdlib::IP::Address $dns_master_ip  = undef,
  Stdlib::IP::Address $dns_slave_ip   = undef,
  Integer             $dns_vip_subnet = 24,
  Stdlib::IP::Address $dns_vip_ip     = undef,
) {

  include '::keepalived'
  include '::foreman_proxy'
  include '::jefirewall'

  package { 'libipset3':
    ensure => installed,
  }
  -> Class['keepalived']

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


  file { '/etc/bind/zones.rfc1912':
    ensure  => file,
    content => '',
    notify  => Class['dns'],
  }

  # Set $dns_masters to empty array if this is the dns master node
  $dns_masters = $::ipaddress ? {
    $dns_master_ip => [],
    default        => [ $::ipaddress, ],
  }

  Dns::Zone<| title == $dns_zone_fwd |> {
    allow_transfer => [ 'localhost', $dns_master_ip, $dns_slave_ip, ],
    also_notify    => [ $dns_master_ip, $dns_slave_ip, ],
    masters        => $dns_masters,
  }

  Dns::Zone<| title == $dns_zone_rev |> {
    allow_transfer => [ 'localhost', $dns_master_ip, $dns_slave_ip, ],
    also_notify    => [ $dns_master_ip, $dns_slave_ip, ],
    masters        => $dns_masters,
    reverse        => true,
  }

  Dns_record {
    provider => bind,
    ddns_key => '/etc/bind/rndc.key',
    server   => 'localhost',
    ttl      => '10800',
  }

  $hosts.each |$k, $v| {
    if ($v['mac'] =~ Dhcp::Macaddress) {
      dhcp::host { $k:
        ip  => $v['ip'],
        mac => $v['mac'],
      }
    }
    dns_record { $k:
      type    => 'A',
      content => $v['ip'],
      domain  => $dns_zone_fwd,
      require => Class['dns'],
    }

    if $v['rev_dns'] != false {
      $rev_ip = join(reverse(split($v['ip'], '\.'), '\.'), '.')
      dns_record { "${rev_ip}.in-addr.arpa":
        type    => 'PTR',
        content => $k,
        domain  => $dns_zone_rev,
        require => Class['dns'],
      }
    }
  }

}
