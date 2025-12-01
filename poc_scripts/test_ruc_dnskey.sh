#!/bin/bash

# test bind
echo "Preparing nameserver..."
docker restart ruc-nameserver
sleep 5
echo "Tesing BIND resolver against ruc_dnskey (w/o SIG)..."
docker restart ruc-bind
docker exec ruc-attacker python3 /root/poc_scripts/ruc_poc.py --resolver_ip 172.22.1.1 --ruc_variant ruc_dnskey --with_sig 0

echo "Preparing nameserver..."
docker restart ruc-nameserver
sleep 5
echo "Tesing BIND resolver against ruc_dnskey (w/ SIG)..."
docker restart ruc-bind
docker exec ruc-attacker python3 /root/poc_scripts/ruc_poc.py --resolver_ip 172.22.1.1 --ruc_variant ruc_dnskey --with_sig 1