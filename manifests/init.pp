# == Class: bind
#
# Installs bind in a chroot and runs the named service
# configuration file variables are kept in hiera and zone
# file data is retrieved from an external source and hiera data.
#
# === Parameters
#
# $data_src: URL for external data, IPs and hostnames
# $data_name: Name for the api to connect to
# $data_key: Token to use when connecting to the api
# $bind_doamins: Hash of domain information used to popuplate named.conf
# $bind_zones: Has of zone information used to populate zone files
#
# === Examples
#
# Hiera domain data
# 
#bind::domains:
#  example.net:
#    type: master
#    slave:
#      - 10.1.16.13
#  16.1.10.in-addr.arpa:
#    type: master
#    slave:
#      - 10.1.16.13
#  0.1.10.in-addr.arpa:
#    type: master
#    CIDR: 22
#    slave:
#      - 10.1.16.13
#
# Hiera zone data
#
#bind::zones:
#  example.net:
#    ttl: 3600
#    nameservers:
#      - ns1.example.net
#      - ns2.example.net
#    data:
#      'foo': bar.example.net.
#      'ns1': 10.1.16.10
#      'ns2': 10.1.16.13
#      'sleep': pillow.other.net.
#  16.1.10.in-addr.arpa:
#    ttl: 3600
#    nameservers:
#      - ns1.example.net
#      - ns2.example.net
#
#  0.1.10.in-addr.arpa:
#    ttl: 3600
#    CIDR: 22
#    nameservers:
#      - ns1.example.net
#      - ns2.example.net
# === Authors
#
# Doug Morris <dmorris@covermymeds.com
#
# === Copyright
#
# Copyright 2015 CoverMyMeds, unless otherwise noted
#
class bind
{
  package{ ['bind9']:
    ensure => present,
  }

  # Data source for names and IP addresses.
  $data_src = hiera('bind::data_src')
  $data_name = hiera('bind::data_name')
  $data_key = hiera('bind::data_key')

  $bind_domains = hiera_hash('bind::domains')

  # Populate the zone files.
  $bind_zones = hiera('bind::zones')

  create_resources(bind::zone_add, $bind_zones)

}
