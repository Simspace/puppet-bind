# === Class: bind::service
#
# This class takes care of services and
# writes our named.conf file.
#
# === Parameters
#
# $forwarders: The servers to forward requests that can't be answered
#              cand be empty.
#
# Doug Morris <dmorris@covermymeds.com
#
# === Copyright
#
# Copyright 2015 CoverMyMeds, unless otherwise noted
#

class bind::service (
  $acls              = {},
  $forwarders        = [],
  $listen            = [],
  $hint              = false,
  $maxrefreshtime    = undef,
  $minrefreshtime    = undef,
  $recursion         = undef,
  $dnssec_enable     = yes,
  $dnssec_validation = yes,
  $zone_notify       = undef,
) {
  validate_hash($acls)
  validate_array($forwarders)
  validate_array($listen)
  validate_bool($hint)

#  $acls = hiera('bind::acls')
  $bind_zones = hiera('bind::zones')

  case $::operatingsystemmajrelease {
    '14.04': {
      $restartcommand = '/usr/sbin/named-checkconf -z && /usr/sbin/service bind9 restart'
      $reloadcommand = '/usr/sbin/named-checkconf -z && /usr/sbin/service bind9 reload'
      $service_name = 'bind9'
    }
    '7': {
      $restartcommand = '/usr/sbin/named-checkconf -z && /usr/bin/systemctl restart named-chroot'
      $reloadcommand = '/usr/sbin/named-checkconf -z && /usr/bin/systemctl reload named-chroot'
      $service_name = 'named-chroot'

      # ensure non-chroot named disabled on el7
      service { 'named':
        ensure => stopped,
        enable => false,
        notify => Service[$service_name],
      }
    }
    default: { fail("Unsupported OS release: ${::operatingsystemmajrelease}") }
  }

  service { $service_name:
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => File['/etc/bind/named.conf'],
  }

  file{'/var/log/named':
    mode    => '0775',
    owner   => root,
    group   => bind,
    ensure  => directory,
  }

  file{'/etc/bind/named.conf':
    mode    => '0640',
    owner   => root,
    group   => bind,
#    require => Package['bind', 'bind-chroot'],
    require => File['/var/log/named'],
    content => template('bind/named_conf.erb'),
    notify  => Exec['named_restart'],
  }

  # Safer restart for the named daemon on config update
  exec{'named_restart':
    refreshonly => true,
    command     => $restartcommand,
  }

  # Use reload instead of restart for zone updates
  exec{'zone_reload':
    refreshonly => true,
    command     => $reloadcommand,
  }

}
