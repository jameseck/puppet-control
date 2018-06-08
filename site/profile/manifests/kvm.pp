class profile::kvm (
) {

  kernel_parameter { [ 'rhqb', 'quiet', ]:
    ensure => absent,
  }

  kernel_parameter { 'console':
    ensure => present,
    value  => 'ttyS0',
  }

  grub_config { 'GRUB_TERMINAL':
    value => 'serial'
  }

  grub_config { 'GRUB_SERIAL_COMMAND':
    value => 'serial --unit=0 --speed=38400 --word=8 --parity=no --stop=1',
  }


}
