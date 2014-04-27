### pdd.yandex.ru Linux/OS X dynamic dns updater

A very basic updater for dynamic DNS services provided by <http://pdd.yandex.ru>. 

## Instructions:

 1. Edit ya.ddns.update.sh in a text editor, and modify the hostname, record_id and token fields.
 2. If desired, set $use_ifconfig='yes' and $iface='eth0'. Otherwise, the script will use http://checkip.dns.he.net to determine your public IP address.
 3. If necessary, `chmod +x ya.ddns.update.sh`.
 4. Run ya.ddns.update.sh.
 5. Use system's cron to schedule the updates. Or LaunchDaemon. Whatever floats your boat.

License: MIT.<br />Warranty: None.

Enjoy!

*Inspired by [bennettp123](https://github.com/bennettp123)'s [dns.ne.net-updater-mac](https://github.com/bennettp123/dns.ne.net-updater-mac)*
