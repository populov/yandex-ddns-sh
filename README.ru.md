# Yandex dDNS updater
### Dynamic DNS клиент для pdd.ya.ru (Linux & OS X)
[In Russian / По-английски](README.md)

Простой шелл-скрипт обновления DNS в сервисе <http://pdd.yandex.ru>.

## Инструкция:

 1. Получите **token** на странице [Token management](https://pddimp.yandex.ru/token/index.xml). Подробности в [руководстве Yandex API](http://api.yandex.ru/pdd/doc/reference/api-dns_get_token.xml).
 2. Откройте **ya.ddns.update.sh** в любом текстовом редакторе, установите *hostname* и *token*.
 3. Можете установить `$use_ifconfig='yes'` и `$iface='eth0'`. Иначе скрипт будет получать внешний IP адрес при помощи сервиса http://checkip.dns.he.net.
 4. Чтобы сделать файл исполняемым, выполните `chmod +x ya.ddns.update.sh` (если нужно).
 5. Запустите **ya.ddns.update.sh**.
 6. Используйте cron для запуска по расписанию. Или LaunchDaemon. Ну или что там у вас.

### Замечания
 * Работает как с основным доменом (*example.com*), так и с субдоменами (*foo.example.com*, *foo.bar.example.com*).
 * "A"-запись в DNS для *hostname* нужно создать до запуска скрипта.
 * **yapdate.sh** более простой скрипт, но не работает, если вы за роутером.

**Лицензия**: [WTFPL](http://www.wtfpl.net) или [MIT](http://opensource.org/licenses/MIT).<br />**Гарантия**: Никакой.

Используйте с удовольствием!

*По мотивам [dns.ne.net-updater-mac](https://github.com/bennettp123/dns.ne.net-updater-mac) от [bennettp123](https://github.com/bennettp123)*
