#!/bin/bash

# Mattermost incoming web-hook URL and user name
url='<incoming webbook uri>'	# example: httpsL//mattermost.example.com/hooks/ere5h9gfbbbk8gdxsei1tt8ewewechjsd
username='zabbix'
icon='<icon_url>'

## Values received by this script:
# To = $1 (Mattermost channel or user to send the message to, specified in the Zabbix web interface; "@username" or "#channel")
# Subject = $2 (usually either PROBLEM or RECOVERY)
# Message = $3 (whatever message the Zabbix action sends, preferably something like "Zabbix server is unreachable for 5 minutes - Zabbix server (127.0.0.1)")

# Get the Mattermost channel or user ($1) and Zabbix subject ($2 - hopefully either PROBLEM or RECOVERY)
to="$1"
subject="$2"
msg="${3//$'\r'/}"
msg="${msg//$'\n'/\\n}"

# Change color emoji depending on the subject - Green (RECOVERY), Red (PROBLEM)
if [ "$subject" == 'RECOVERY' ]; then
        color="#00ff33"
elif [ "$subject" == 'PROBLEM' ]; then
        color="#ff2a00"
fi

# The message that we want to send to Mattermost  is the "subject" value ($2 / $subject - that we got earlier)
#  followed by the message that Zabbix actually sent us ($3)
message="${subject}: ${msg}"

# Build our JSON payload and send it as a POST request to the Mattermost incoming web-hook URL
payload="{\"icon_url\": \"$icon\", \"attachments\": [ {\"color\": \"${color}\", \"text\": \"${message}\"} ], \"channel\": \"${to}\", \"username\": \"${username}\", \"icon_emoji\": \"${emoji}\"}"
echo "${payload}" | curl -f -m 5 --header 'Content-Type: application/json' --data @- $url
exit $?
