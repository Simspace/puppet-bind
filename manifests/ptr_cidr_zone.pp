# === Define: bind::ptr_cidr_zone
#
# Creates and adds reverse zone files for the Bind server
#
# === Authors
#
# Doug Morris <dmorris@covermymeds.com>
#
# === Copyright
#
# Copyright 2015 CoverMyMeds, unless otherwise noted
#
define bind::ptr_cidr_zone (
  $nameservers,
  $zone         = $title,
  $ttl          = 3600,
  $refresh      = 10800,
  $retry        = 3600,
  $expire       = 604800,
  $negresp      = 300,
) {

  $cidr_ptr = inline_template('<%= @name.chomp("0/24").split(".").reverse.join(".").concat(".in-addr.arpa") %>')
  $query_zone = chop($zone)

  $cidr_ptr_zone = parsejson(dns_array($::bind::data_src, $::bind::data_name, $::bind::data_key, $query_zone))

  file{ "/var/cache/bind/zone_${cidr_ptr}":
    ensure  => present,
    owner   => root,
    group   => bind,
    mode    => '0640',
    content => template('bind/ptr_cidr_zone_file.erb'),
    notify  => Exec["update_zone${cidr_ptr}"],
  }

  # This is needed to update the serial number on zone files
  exec{"update_zone${cidr_ptr}":
    refreshonly => true,
    path        => '/bin',
    command     => "sed -e \"s/serialnumber/`date +%y%m%d%H%M`/g\" /var/cache/bind/zone_${cidr_ptr} > /var/cache/bind/zone_${cidr_ptr}.db",
    notify      => Exec["zone_compile${cidr_ptr}"],
  }

  # Here the zone is compiled to verify good data
  exec{"zone_compile${cidr_ptr}":
    refreshonly => true,
    command     => "/usr/sbin/named-compilezone -o /var/cache/bind/zone_${cidr_ptr} ${cidr_ptr} /var/cache/bind/zone_${cidr_ptr}.db",
    notify      => Exec['zone_reload'],
  }

}
