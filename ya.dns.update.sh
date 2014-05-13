#!/bin/sh
# http://projects.populov.com/yandex-ddns-sh/

api_url="https://pddimp.yandex.ru/nsapi"
ttl=3600
previous_file_prefix=/tmp/ddns
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
  if [ "$use_ifconfig" = "yes" ]; then
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
#    currentip=$(curl -4 -s "http://checkip.dns.he.net" | grep -iE "Your ?IP ?address ?is ?: ?" | sed -r 's/.*\s+([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/')
    currentip=$(wget -qO- "http://checkip.dns.he.net" | grep -iE "Your ?IP ?address ?is ?: ?" | sed -r 's/.*\s+([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/')
  fi

  previous_file="$previous_file_prefix.$hostname"
  previous=$(cat "$previous_file" 2>/dev/null)
  oldip=$(echo -n "$previous" | sed 's/^[^:]*://')
  record_id=$(echo -n "$previous" | sed 's/:.*$//')

  if [ "_$oldip" = "_" ]; then
    oldip="unknown"
#    getrecords=$(curl -4 -s "$api_url/get_domain_records.xml" -d token=$token -d domain=$domain -d subdomain=$subdomain)
    getrecords=$(wget -qO- "$api_url/get_domain_records.xml?token=$token&domain=$domain&subdomain=$subdomain")
    getRetval=$?
    if [ $getRetval -eq 0 ]; then
      message=$(echo "$getrecords" | grep error | sed -r 's/(^.*<error>)|(<\/error>.*$)//g')
    else
      message="HTTP error"
    fi
    if [ "_$message" = "_ok" ]; then
      domaintest="domain=\"?$hostname\"?[^>]+type=\"?A\"?[^<]+"
      records=$(echo "$getrecords" | grep -E $domaintest)
      if [ "_$records" = "_" ]; then
        logmsg="$hostname DNS \"A\" record not found; skip"
        logger -i -t $tag "$logmsg"
        echo $logmsg
        continue
      fi
      record=$(echo $records | sed -r 's/.+domain=\"?'"$hostname"'"?[^>]+type="A"//' | sed 's/<\/record.*//')
      previous_id=$record_id
      record_id=$(echo "$record" | sed -r 's/(^.*\id=\")|(\">.*)//g')
#      echo "record_id=$record_id"
      remoteip=$(echo "$record" | sed -r 's/.*>//g')
      echo "$hostname remote IP: $remoteip"
      if [ "_$remoteip" != "_$oldip" ] || [ "_$record_id" != "_$previous_id"]; then
        logger -i -t "$tag" "Remote: $hostname:$remoteip"
        echo "$record_id:$remoteip" > "$previous_file"
        oldip=$remoteip
      fi
    else
      logmsg="Error getting $domain DNS records: $message"
      logger -i -t $tag "$logmsg"
      echo $logmsg
      continue
    fi
  fi

  if [ "_$currentip" != "_$oldip" ]; then
    logmsg="$hostname: old IP: $oldip; current IP: $currentip; updating..."
    logger -i -t $tag "$logmsg"
    echo $logmsg
#    editResult=$(curl -4 -s "$api_url/edit_a_record.xml" -d token=$token -d domain=$domain -d subdomain=$subdomain -d record_id=$record_id -d ttl=$ttl -d content=$currentip)
    editResult=$(wget -qO- "$api_url/edit_a_record.xml?token=$token&domain=$domain&subdomain=$subdomain&record_id=$record_id&ttl=$ttl&content=$currentip")
    editRetval=$?
    if [ $editRetval -eq 0 ]; then
      message=$(echo "$editResult" | grep error | sed -r 's/(^.*<error>)|(<\/error>.*$)//g')
    else
      message="HTTP error"
    fi
    if [ "_$message" = "_ok" ]; then
      echo "$hostname: updated"
      logger -i -t "$tag" "$hostname:$currentip"
      echo "$record_id:$currentip" > "$previous_file"
    else
      logmsg="Error updating $hostname: $message"
      logger -i -t $tag "$logmsg"
      echo $logmsg
    fi
  else
    logmsg="$hostname: old IP same as current IP: $currentip; not updating"
#    logger -i -t $tag "$logmsg"
    echo $logmsg
    editRetval=0
  fi

  retval=`bc <<EOF
    $editRetval + $retval
EOF
`

done

exit $retval
