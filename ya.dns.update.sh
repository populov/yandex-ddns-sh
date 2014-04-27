#!/bin/bash

api_url="https://pddimp.yandex.ru/nsapi"
ttl=3600
previous_file_prefix=/tmp/dyndns
tag=ru.yandex.ddns

retval=0

use_ifconfig='no' # set this to 'yes' to use ifconfig to determine local IP addresses.
iface='eth0' # only needed if $use_ifconfig='yes'

for hostname_token in \
  "demo.example.com:0290c6501877031d5bcfe880522a1576c4f7144bbeedbd51f3e9f7b8" \
#  "hostname2:token2" #etc...
do

  hostname=$( echo -n "$hostname_token" | sed 's/:.*$//' )
#  echo "Hostname: $hostname"
  token=$( echo -n "$hostname_token" | sed 's/.*://' )
#  echo "Token: $token"
  subdomain=$( echo -n "$hostname" | sed -r 's/\.?[^.]*\.[^.]*$//' )
#  echo "Subdomain: $subdomain"
  domain=$( echo -n "$hostname" | sed s/^"$subdomain\."// )
#  echo "Domain: $domain"

  currentip=''
  if [ "$use_ifconfig" == "yes" ]; then
    if which ip >/dev/null 2>&1; then
      currentip=$(ip addr show dev "$iface" | grep inet\ .*scope\ global | sed -E 's/[^0-9]*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\/[0-9]{1,2}.*/\1/g')
    elif which ifconfig >/dev/null 2>&1; then
      currentip=$(ifconfig en0 inet | grep -E '^.*inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*$' | sed -E 's/^.*inet ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*$/\1/')
    else
      logmsg="$hostname: could not determine local IP address"
      logger -i -t $tag "$logmsg"
      echo $logmsg
      retval=1
      break
    fi
  else
    currentip=$(curl -4 -s "http://checkip.dns.he.net" | grep -iE "Your ?IP ?address ?is ?: ?" | sed -r 's/.*\s+([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/')
  fi

  previous_file="$previous_file_prefix.$hostname"
  previous=$(cat "$previous_file" 2>/dev/null)
  oldip=$(echo -n "$previous" | sed 's/^[^:]*://')
  record_id=$(echo -n "$previous" | sed 's/:.*$//')

  if [ "_$oldip" = "_" ]; then
    oldip="unknown"
    allrecords=$(curl -4 -s "$api_url/get_domain_records.xml" -d token=$token -d domain=$domain -d subdomain=$subdomain)
    record=$(echo $allrecords | sed -r 's/.+domain=\"?'"$hostname"'"?[^>]+type="A"//' | sed 's/<\/record.*//')
#    echo "Found record: $record"
    record_id=$(echo "$record" | sed -r 's/(^.*\id=\")|(\">.*)//g')
#    echo "record_id=$record_id"
    setip=$(echo "$record" | sed -r 's/.*>//g')
    echo "Remote IP: $setip"
    if [ "_$setip" != "_$oldip" ]; then
      echo "$record_id:$currentip" > "$previous_file"
      oldip=$setip
    fi
  fi

  if [ "_$record_id" = "_" ]; then
    logmsg = "record_id is unknown; exit"
    logger -i -t $tag "$logmsg"
    echo $logmsg
    exit $retval
  fi

  if [ "_$currentip" != "_$oldip" ]; then
    logmsg="$hostname: old IP: $oldip; current IP: $currentip; updating..."
    logger -i -t $tag "$logmsg"
    echo $logmsg
    result1=$(curl -4 -s "$api_url/edit_a_record.xml" -d token=$token -d domain=$domain -d subdomain=$subdomain -d record_id=$record_id -d ttl=$ttl -d content=$currentip)
    retval1=$?
#    echo "Retval = $retval1 Result: $result1"
    message=$(echo "$result1" | grep error | sed -r 's/(^.*<error>)|(<\/error>.*$)//g')
    echo "Response message: $message"
    if [ "_$message" = "_ok" ]; then
      logger -i -t "$tag" "$hostname:$currentip"
      echo "$record_id:$currentip" > "$previous_file"
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
