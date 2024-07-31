#!/usr/bin/awk -f
BEGIN { key = ARGV[1]; field = ARGV[2]; ARGV[1]=ARGV[2]="" }
$1 == key { print $field }
