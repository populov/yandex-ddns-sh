#!/bin/sh
# http://projects.populov.com/yandex-ddns-sh/

domain=example.com
subdomain=foo  # @ for primary domain
token=TOKEN    #see https://tech.yandex.ru/pdd/doc/concepts/access-docpage/
record_id=ID   #see https://tech.yandex.ru/pdd/doc/reference/dns-list-docpage/
ttl=900
iface=eth0
cache_file=/tmp/ddns.ip.txt

if test -f $cache_file
then
  cache_ip=$(cat $cache_file)
fi

current_ip=`/sbin/ifconfig $iface | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1`

if [ "$current_ip" != "$cache_ip" ]
then
  echo "Updating Yandex DNS with" $current_ip
  echo `date`  "Updating with IP" $current_ip >> /usr/logs/yandex-dns-update.log
  wget --no-check-certificate --header="PddToken: ${token}" \
       --post-data "&domain=${domain}&subdomain=${subdomain}&record_id=${record_id}&ttl=${ttl}&content=${current_ip}" \
       -qO- "https://pddimp.yandex.ru/api2/admin/dns/edit"
  rm -f $cache_file
  echo $current_ip > $cache_file
fi

