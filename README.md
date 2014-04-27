# pdd.ya.ru Linux/OS X dDNS updater

A very basic shell script updater for dynamic DNS services provided by <http://pdd.yandex.ru>. 

## Instructions:

 1. Get **token** at [Token management](https://pddimp.yandex.ru/token/index.xml) page. See [Yandex API manual](http://api.yandex.ru/pdd/doc/reference/api-dns_get_token.xml) for details.
 2. Edit **ya.ddns.update.sh** in a text editor, and modify the *hostname*, and *token* fields.
 3. If desired, set `$use_ifconfig='yes'` and `$iface='eth0'`. Otherwise, the script will use http://checkip.dns.he.net to determine your public IP address.
 4. If necessary, `chmod +x ya.ddns.update.sh`.
 5. Run **ya.ddns.update.sh**.
 6. Use system's cron to schedule the updates. Or LaunchDaemon. Whatever floats your boat.

License: MIT.<br />Warranty: None.

### Notes
 * Works both for primary domain (*example.com*) and subdomains (*foo.example.com*, *foo.bar.example.com*).
 * "A" record for *hostname* must exist before you run this script.
 * Using wget. You can uncomment 3 lines, using curl instead.

Enjoy!

*Inspired by [bennettp123](https://github.com/bennettp123)'s [dns.ne.net-updater-mac](https://github.com/bennettp123/dns.ne.net-updater-mac)*

