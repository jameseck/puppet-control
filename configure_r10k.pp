class { 'r10k':
  sources           => {
    'puppet' => {
      'remote'  => 'https://github.com/jameseck/puppet-control.git',
      'basedir' => "${::settings::confdir}/environments",
      'prefix'  => false,
    }
  },
  purgedirs         => ["${::settings::confdir}/environments"],
  manage_modulepath => false,
}
