#!/usr/bin/env bash
set -e
mkdir -p /dev/net /var/log/openvpn
[ -c /dev/net/tun ] || mknod /dev/net/tun c 10 200
# VPN istemcileri için NAT (lab)
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE 2>/dev/null || true
exec openvpn --config /etc/openvpn/server.conf
