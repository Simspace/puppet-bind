# === Define: bind::zone_add
#
# Creates and adds zone files for the Bind server
#
# === Parameters
#
# $ttl: Time to live for the zone file
# $type: Forward or reverse zone file
# $data: Hash of hostnames and IP addresses
# $cidr CIDR subnet size, will be overridden if passed in
# $nameservers: Servers that are authoritative for this zone
#
# === Authors
#
# Doug Morris <dmorris@covermymeds.com>
#
# === Copyright
#
# Copyright 2015 CoverMyMeds, unless otherwise noted
#
define bind::zone_add (
  $ttl          = 3600,
  $type		= undef,
  $refresh      = 10800,
  $retry        = 3600,
  $expire       = 604800,
  $negresp      = 300,
  $type         = undef,
  $data         = undef,
  $cidr         = 24,
  $nameservers  = undef,
) {

  if $type == 'master' {
    # Check if this is a reverse zone
    if $name =~ /^(\d+).*arpa$/ {
      bind::ptr_zone { $name:
        zone        => $name,
        cidrsize    => $cidr,
        ttl         => $ttl,
        refresh     => $refresh,
        retry       => $retry,
        expire      => $expire,
        negresp     => $negresp,
        nameservers => $nameservers,
      }
    }
    else {
      bind::fwd_zone { $name:
        zone        => $name,
        ttl         => $ttl,
        refresh     => $refresh,
        retry       => $retry,
        expire      => $expire,
        negresp     => $negresp,
        type        => $type,
        data        => $data,
        cidr        => $cidr,
        nameservers => $nameservers,
      }
    }
  }

}
