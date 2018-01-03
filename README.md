Zabbix Matter Most Bot
========================

About
-----
zabbixMatterBot is a script that takes in json from zabbix, parses it, and outputs stuff to a channel.


#### Versions
i dunno, only tested with 3.4, but should work on anything newer as long as you can pass all the vars

#### Huge thanks and appreciation to:
* To everyone that this was sort of based on
* [Allan Graham](https://github.com/muokata) after a million googles was the i started from. (https://github.com/muokata/zabbix-mattermost-alertscript)
* [Eric OC](https://github.com/ericoc) where this was originally forked from (https://github.com/ericoc/zabbix-slack-alertscript)
* [Paul Reeves](https://github.com/pdareeves/) for the hint that Mattermost changed their API/URLs!
* [Igor Shishkin](https://github.com/teran) for the ability to message users as well as channels!
* Leslie at AspirationHosting for confirming that this script works on Zabbix 1.8.2!
* [Hiromu Yakura](https://github.com/hiromu) for escaping quotation marks in the fields received from Zabbix to have valid JSON!
* [Devlin Gonçalves](https://github.com/devlinrcg), [tkdywc](https://github.com/tkdywc), [damaarten](https://github.com/damaarten), and [lunchables](https://github.com/lunchables) for Zabbix 3.0 AlertScript documentation, suggestions and testing!

Installation
------------

### The script itself

install the JSON perl module

```
cpanm JSON Data::Dumper

```

copy the perl script mattermost.pl to your alert scripts directory

```
	[root@zabbix ~]# grep AlertScriptsPath /etc/zabbix/zabbix_server.conf
	### Option: AlertScriptsPath
	AlertScriptsPath=/var/lib/zabbix/alertscripts

	[root@zabbix ~]# ls -lh /var/lib/zabbix/
	-rwxr-xr-x 1 root root 1.6K Nov 19 20:04 /var/lib/zabbix/alertscripts/zabbixMatterBot.pl

```

Configuration
-------------

### mattermost web-hook

An incoming web-hook integration must be created within your Mattermost account which can be done at https://<your mattermost uri>/chattr/integrations/incoming_webhooks:


the incoming web-hook URL would be something like:

	https://<your mattermost uri>/hooks/ere5h9gfbbbk8gdxsdsduwuicsd

save it, you'll need it in a second.


### Within the Zabbix web interface

When logged in to the Zabbix servers web interface with super-administrator privileges, navigate to the "Administration" tab, access the "Media Types" sub-tab, and click the "Create media type" button.

You need to create a media type as follows:

* **Name**: Mattermost
* **Type**: Script
* **Script name**: mattermost.pl

add the following script parameters (you can use my image, but all are required right now)

```
https://drew.beer/images/bots/monitorBot.jpg
```

* `{ALERT.SENDTO}`
* `http://webhook.url.from.above/oranges`
* `bots name here`
* `https://drew.beer/images/bots/monitorBot.jpg`
* `{ALERT.MESSAGE}`


create a user like zabbixBot, and set media then add choose the new script, and the channel you want it to go to like #alerts or @someone.

## supported Types
so i wrote this to support triggers, but then i expanded it further.

in the examples folder you'll see a bunch of JSON, make sure you minify it

trigger.json - use for the trigger types in actions
internal.json - for internal unsupported type triggers, and ldd

have not looked into the discovery or registration messages yet, its really just pulling all the macros and seeing what comes out. you can enable debugging and play with messages.

if you change notifyType from detailed to anything else then you'll get attachment style notifications for triggers. its bulkier but more information, still working on trying to exclude un-needed duplicate items.


Testing
-------
try this as an examples

```

./mattermost.pl monitoring https://your.webhook/url zabbix https://drew.beer/images/bots/monitorBot.jpg '{
  "type": "trigger",
  "notifyType": "detailed",
  "hostname": "{HOST.NAME}",
  "tName": "{TRIGGER.NAME}",
  "tSeverity": "{TRIGGER.SEVERITY}",
  "tDescription": "{TRIGGER.DESCRIPTION}",
  "tStatus": "{TRIGGER.STATUS}",
  "tUrl": "https://domain.com/tr_events.php?triggerid={TRIGGER.ID}&eventid={EVENT.ID}",
  "tValue": "{TRIGGER.VALUE}",
  "iName1": "{ITEM.NAME1}",
  "iName2": "{ITEM.NAME2}",
  "iName3": "{ITEM.NAME3}",
  "iName4": "{ITEM.NAME4}",
  "iValue1": "{ITEM.VALUE1}",
  "iValue2": "{ITEM.VALUE2}",
  "iValue3": "{ITEM.VALUE3}",
  "iValue4": "{ITEM.VALUE4}"
}
'

```

you can always enable debug $debug = 1; and you should get what you need out of it defaults to /tmp/zabbix-mattermost.log

good luck

More Information
----------------
* [Mattermost incoming web-hook functionality](https://docs.mattermost.com/developer/webhooks-incoming.html)
* [Zabbix 2.2 custom alertscripts documentation](https://www.zabbix.com/documentation/2.2/manual/config/notifications/media/script)
* [Zabbix 2.4 custom alertscripts documentation](https://www.zabbix.com/documentation/2.4/manual/config/notifications/media/script)
* [Zabbix 3.x custom alertscripts documentation](https://www.zabbix.com/documentation/3.0/manual/config/notifications/media/script)
