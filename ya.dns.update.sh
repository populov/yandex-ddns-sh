#!/bin/bash

url="https://pddimp.yandex.ru/nsapi/edit_a_record.xml"
ttl=3600
previous_file_prefix=/tmp/.dyndns
tag=ru.yandex.ddns

retval=0

use_ifconfig='no' # set this to 'yes' to use ifconfig to determine local IP addresses.
iface='eth0' # only needed if $use_ifconfig='yes'

for hostname_id_token in \
  "home.populov.tk:19533680:0290c6501877031d5bcfe880522a1576c4f7144bbeedbd51f3e9f7b8" \
#  "hostname2:record2:token2" #etc...
do

  hostname=$( echo -n "$hostname_id_token" | sed 's/:.*$//' )
#  echo "Hostname: $hostname"
  subdomain=$( echo -n "$hostname" | sed 's/\.[^.]*\.[^.]*$//' )
#  echo "Subdomain: $subdomain"
  domain=$( echo -n "$hostname" | sed s/^"$subdomain\."// )
#  echo "Domain: $domain"
  id_token=$( echo -n "$hostname_id_token" | sed 's/^[^:]*://')
  record_id=$( echo -n "$id_token" | sed 's/:.*$//' )
#  echo "record_id: $record_id"
  token=$( echo -n "$id_token" | sed 's/[^:]*://' )
#  echo "token: $token"

  currentip=''
  if [ "$use_ifconfig" == "yes" ]; then
    if which ip >/dev/null 2>&1; then
      currentip=$(ip addr show dev "$iface" | grep inet\ .*scope\ global | sed -E 's/[^0-9]*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\/[0-9]{1,2}.*/\1/g')
    elif which ifconfig >/dev/null 2>&1; then
      currentip=$(ifconfig en0 inet | grep -E '^.*inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*$' | sed -E 's/^.*inet ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*$/\1/')
    else
      logger -i -t "$tag" "$hostname: could not determine local IP address"
      retval=1
      break
    fi
  else
    currentip=$(curl -4 -s "http://checkip.dns.he.net" | grep -iE "Your ?IP ?address ?is ?: ?" | sed -r 's/.*\s+([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/')
  fi

  previous_file="$previous_file_prefix.$hostname"
  oldip=$(cat "$previous_file" 2>/dev/null)

  if [ "_$oldip" = "_" ]; then
    oldip="unknown"
  fi

  if [ "_$currentip" != "_$oldip" ]; then
    logmsg="$hostname: old IP: $oldip; current IP: $currentip; updating..."
    logger -i -t $tag "$logmsg"
    echo $logmsg
    request="$url?token=$token&domain=$domain&subdomain=$subdomain&record_id=$record_id&ttl=$ttl&content=$currentip"
#    echo "Request: $request"
    result1=$(curl -4 -s "$request")
    retval1=$?
#    echo "Retval = $retval1 Result: $result1"
    message=$(echo "$result1" | grep error | sed -r 's/(^.*<error>)|(<\/error>.*$)//g')
    echo "Response message: $message"
    if [ "_$message" = "_ok" ]; then
      logger -i -t "$tag" "$hostname:$currentip"
      echo "$currentip" > "$previous_file"
    fi
  else
    logmsg="$hostname: old IP same as current IP: $currentip; not updating"
#    logger -i -t $tag "$logmsg"
    echo $logmsg
    retval1=0
  fi

  retval=`bc <<EOF
    $retval1 + $retval
EOF
`

done

exit $retval
