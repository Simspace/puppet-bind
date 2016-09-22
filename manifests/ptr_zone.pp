# === Define: bind::ptr_zone
#
# Creates and adds reverse zone files for the Bind server
#
#
# === Authors
#
# Doug Morris <dmorris@covermymeds.com>
#
# === Copyright
#
# Copyright 2015 CoverMyMeds, unless otherwise noted
#
define bind::ptr_zone (
  $nameservers,
  $cidrsize,
  $zone    = $title,
  $ttl     = 3600,
  $refresh = 10800,
  $retry   = 3600,
  $expire  = 604800,
  $negresp = 300,
) {

  # PTR data from hiera
  $ptr_data = pick($::bind::bind_zones[$name][data], {})
  validate_hash($ptr_data)

  # Check if we are working with something other than a class C subnet.
  if $cidrsize != 24 {
    $subs = inline_template('<%= @name.chomp(".in-addr.arpa").split(".").reverse.join(".").concat(".0/") %>')
    $subnum = "${subs}${cidrsize}"
    $nets = cidr_zone($subnum)
    bind::ptr_cidr_zone { $nets:
      nameservers => $nameservers,
      zone        => $subs,
      ttl         => $ttl,
      refresh     => $refresh,
      retry       => $retry,
      expire      => $expire,
      negresp     => $negresp,
    }
  } else {

    $ptr_zone = inline_template('<%= @name.chomp(".in-addr.arpa").split(".").reverse.join(".").concat(".0")  %>')
    #$add_ptr_zone = parsejson(dns_array($::bind::data_src, $::bind::data_name, $::bind::data_key, $ptr_zone))
    $add_ptr_zone = $ptr_data

    file{ "/var/cache/bind/zone_${name}":
      ensure  => present,
      owner   => root,
      group   => bind,
      mode    => '0640',
      content => template('bind/ptr_zone_file.erb'),
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
}
