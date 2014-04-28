#!/bin/sh
# https://github.com/populov/yandex-ddns-bash

domain=example.com
subdomain=foo  # @ for primary domain
token=TOKEN    #see http://api.yandex.ru/pdd/doc/reference/api-dns_get_token.xml
record_id=ID   #see http://api.yandex.ru/pdd/doc/reference/api-dns_get_domain_records.xml
ttl=900
iface=eth0
cache=/tmp/ip.txt

if test -f $cache
then
  cache_ip=$(cat $cache)
fi

current_ip=`/sbin/ifconfig $iface | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1`

if [ "$current_ip" != "$cache_ip" ]; then
  echo "Updating Yandex DNS with" $current_ip
  echo `date`  "Updating with IP" $current_ip >> /usr/logs/yandex-dns-update.log
  wget --no-check-certificate -qO- "https://pddimp.yandex.ru/nsapi/edit_a_record.xml?token=${token}&domain=${domain}&subdomain=${subdomain}&record_id=${record_id}&ttl=${ttl}&content=${current_ip}"
  rm -f $cache
  echo $current_ip > $cache
fi

