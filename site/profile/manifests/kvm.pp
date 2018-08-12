class profile::kvm (
) {

  kernel_parameter { [ 'rhqb', 'quiet', ]:
    ensure => absent,
  }

#  kernel_parameter { 'console':
#    ensure => present,
#    value  => 'ttyS0',
#  }

  grub_config { 'GRUB_TERMINAL':
    value => 'console serial',
  }

  grub_config { 'GRUB_TERMINAL_OUTPUT':
    value => 'console serial',
  }

  file_line { 'GRUB_CMDLINE_LINUX_DEFAULT':
    path   => '/etc/default/grub',
    match  => '^GRUB_CMDLINE_LINUX_DEFAULT=',
    line   => 'GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"',
    notify => Exec['grub2-mkconfig'],
  }

  file_line { 'grub serial command':
    path   => '/etc/default/grub',
    match  =>  '^GRUB_SERIAL_COMMAND=',
    line   => 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"',
    notify => Exec['grub2-mkconfig'],
  }

  exec { 'grub2-mkconfig':
    command     => '/usr/sbin/grub2-mkconfig /boot/grub2/grub.cfg',
    refreshonly => true,
  }

}
