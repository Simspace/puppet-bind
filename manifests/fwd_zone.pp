# === Define: bind::fwd_zone
#
# Creates forward lookup zones for bind 9
#
# === Authors
#
# Doug Morris <dmorris@covermymeds.com>
#
# === Copyright
#
# Copyright 2015 CoverMyMeds, unless otherwise noted
#
define bind::fwd_zone (
  $zone,
  $nameservers,
  $ttl          = 3600,
  $refresh      = 10800,
  $retry        = 3600,
  $expire       = 604800,
  $negresp      = 300,
  $type         = undef,
  $data         = undef,
  $cidr         = 24,
) {

  # CNAME data from hiera
  $cname_data = pick($::bind::bind_zones[$name][data], {})
  validate_hash($cname_data)

  # Use custom function to query external source for names and IP addresses.
  $add_zone = []
  #$add_zone = parsejson(dns_array($::bind::data_src, $::bind::data_name, $::bind::data_key, $name))
  if $add_zone == [] {
    $clean_zone = {}
  }
  else {
    $clean_zone = $add_zone
  }

  # Merge data from custom function and hiera.
  $merged_zone = merge($clean_zone, $cname_data)
  validate_hash($merged_zone)

  file{ "/var/cache/bind/zone_${name}":
    ensure  => present,
    owner   => root,
    group   => bind,
    mode    => '0640',
    content => template('bind/fwd_zone_file.erb'),
    notify  => Exec["update_zone${name}"],
  }

  # This is needed to update the serial number on zone files
  exec{"update_zone${name}":
    refreshonly => true,
    path        => '/bin',
    command     => "sed -e \"s/serialnumber/`date +%y%m%d%H%M`/g\" /var/cache/bind/zone_${name} > /var/cache/bind/zone_${name}.db",
    notify      => Exec["zone_compile${name}"],
  }

  # Here the zone is compiled to verify good data
  exec{"zone_compile${name}":
    refreshonly => true,
    command     => "/usr/sbin/named-compilezone -o /var/cache/bind/zone_${name} ${name} /var/cache/bind/zone_${name}.db",
    notify      => Exec['zone_reload'],
  }

}
