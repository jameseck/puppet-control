class profile::kvm (
) {

  kernel_parameter { [ 'rhqb', 'quiet', ]:
    ensure => absent,
  }

#  kernel_parameter { 'console':
#    ensure => present,
#    value  => 'ttyS0',
#  }

  file_line { 'GRUB_TERMINAL':
    path  => '/etc/default/grub',
    match => '^GRUB_TERMINAL=',
    line  => 'GRUB_TERMINAL="console serial"',
  }

  -> file_line { 'GRUB_TERMINAL_OUTPUT':
    path  => '/etc/default/grub',
    match => '^GRUB_TERMINAL_OUTPUT=',
    line  => 'console serial',
  }

  -> file_line { 'GRUB_CMDLINE_LINUX_DEFAULT':
    path  => '/etc/default/grub',
    match => '^GRUB_CMDLINE_LINUX_DEFAULT=',
    line  => 'GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"',
  }

  -> file_line { 'grub serial command':
    path  => '/etc/default/grub',
    match =>  '^GRUB_SERIAL_COMMAND=',
    line  => 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"',
  }

  ~> exec { 'grub2-mkconfig':
    command     => '/usr/sbin/grub2-mkconfig /boot/grub2/grub.cfg',
    refreshonly => true,
  }

}
