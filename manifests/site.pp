require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $luser,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::luser}"
  ]
}

File {
  group => 'staff',
  owner => $luser
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => Class['git']
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # Core Boxen modules, needed for most installations
  include dnsmasq
  include git
  include nginx

  # Fail if full disk encryption is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # Install Node via nodenv
  include nodejs::v0_10
  include nodejs::v0_8

  # Install Ruby via rbenv
  include ruby::1_8_7
  include ruby::1_9_3
  include ruby::2_0_0

  # Set Ruby 1.9.3 as default version
  class { 'ruby::global':
      version => '1.9.3'
  }

  # Install useful rbenv plugins
  ruby::plugin { 'rbenv-vars':
    version => 'v1.2.0',
    source  => 'sstephenson/rbenv-vars'
  }

  ruby::plugin { 'rbenv-gem-rehash':
    version => 'v1.0.0',
    source  => 'sstephenson/rbenv-gem-rehash'
  }

  ruby::plugin { 'rbenv-gemset':
    version => 'v0.3.0',
    source  => 'jamis/rbenv-gemset'
  }

  # Install a homebrewed python
  include python
  include xquartz

  # Other modules
  include hub
  include java
  include wget
  include chrome
  include firefox

  # Homebrew packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar',
      'cmake',
      'readline',
      'gnu-sed',
      'coreutils',
      'tree'
    ]:
  }

  # Create symlink to boxen in ${HOME}/src (or whatever source directory is set to)
  file { "${boxen::config::srcdir}/my-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }
}
