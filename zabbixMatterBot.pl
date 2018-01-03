#!/usr/bin/perl
# https://github.com/drewbeer/zabbix-mattermost-alertscript DrewBeer
# passes data in and curls it out via json to mattermost webhooks as attachments.
# you can use this as you wish, free as in beer, life is that way.
# minify your json before you set it in zabbix, it will make your life easier

use warnings;
use strict;
use JSON;
use Data::Dumper;

# turn on file logging to /tmp/zabbix-mattermost.log
my $debug = 0;
my $logFH;
my $zabbixData = ();

# debug log the incoming data
if ($debug) {
  open($logFH, '>>', '/tmp/zabbix-mattermost.log');
  my $dump = Dumper(@ARGV);
  print $logFH "args:\n$dump\n";
}

# get the data
my ($channel, $hook, $botName, $iconUrl, $body) = @ARGV;

# decode the body
$zabbixData = decode_json $body;

# build the payload;
my $payload;

if ($zabbixData->{'type'} eq "trigger") {
  $payload = processTrigger($zabbixData);
} elsif ($zabbixData->{'type'} eq "internal") {
  $payload = processInternal($zabbixData);
}

# final debug
if ($debug) {
  print $logFH "final payload: $payload\n";
}

# send the payload
if ($payload) {
  sendPayload($payload);
}

exit;

# send the payload
sub sendPayload {
  my($payload) = @_;
  my $cmd = qq( curl -s -i -X POST --data-urlencode '$payload' $hook > /dev/null);
  if ($debug) {
    $cmd = qq( curl -i -X POST --data-urlencode '$payload' $hook );
  }
  my $cmdOutput = `$cmd`;

  # final debug
  if ($debug) {
    print $logFH "curl:\n$cmd \n$cmdOutput\n";
  }
}

# Trigger Data parsing
# will take data in from zabbix and build an attachment or a simple message
sub processTrigger {
  my $data = shift;
  my $attach = ();

  # add some core details
  if ($data->{'notifyType'} eq 'detailed') {
    # add core details
    $attach->{'fallback'} = "$data->{'hostname'}:$data->{'tName'}:$data->{'tStatus'}";
    $attach->{'author_name'} = $data->{'hostname'};
    $attach->{'title_link'} = $data->{'tUrl'};
    $attach->{'title'} = $data->{'tName'};

    # description if it exists
    if ($data->{'tDescription'}) {
      $attach->{'text'} = $data->{'tDescription'};
    } else {
      $attach->{'text'} = "";
    }

    # next two columns
    $attach->{'fields'}[0]->{'title'} = 'Status';
    $attach->{'fields'}[0]->{'short'} = \1;
    if ($data->{'tStatus'} eq 'OK') {
      $attach->{'fields'}[0]->{'value'} = "Is $data->{'tStatus'}";
    } else {
      $attach->{'fields'}[0]->{'value'} = "$data->{'tStatus'} is $data->{'tSeverity'}";
    }

    if ($data->{'iValue1'} !~  /.*UNKNOWN.*/) {
      $attach->{'fields'}[1]->{'title'} = $data->{'iName1'};
      $attach->{'fields'}[1]->{'value'} = $data->{'iValue1'};
      $attach->{'fields'}[1]->{'short'} = \1;
    }

    # secondary columns if they exist
    if ($data->{'iValue2'} !~  /.*UNKNOWN.*/) {
      $attach->{'fields'}[2]->{'title'} = $data->{'iName2'};
      $attach->{'fields'}[2]->{'value'} = $data->{'iValue2'};
      $attach->{'fields'}[2]->{'short'} = \1;
    }

    if ($data->{'iValue3'} !~  /.*UNKNOWN.*/) {
      $attach->{'fields'}[3]->{'title'} = $data->{'iName3'};
      $attach->{'fields'}[3]->{'value'} = $data->{'iValue3'};
      $attach->{'fields'}[3]->{'short'} = \1;
    }

    if ($data->{'iValue4'} !~  /.*UNKNOWN.*/) {
      $attach->{'fields'}[4]->{'title'} = $data->{'iName4'};
      $attach->{'fields'}[4]->{'value'} = $data->{'iValue4'};
      $attach->{'fields'}[4]->{'short'} = \1;
    }

  # select the color
    if ($data->{'tSeverity'} =~ /\bNot classified\b/) {
      $attach->{'color'} = '#33b5e5';
    } elsif ($data->{'tSeverity'} =~ /\bInformation\b/) {
      $attach->{'color'} = '#0099CC';
    } elsif ($data->{'tSeverity'} =~ /\bWarning\b/) {
      $attach->{'color'} = '#ffbb33';
    } elsif ($data->{'tSeverity'} =~ /\bAverage\b/) {
      $attach->{'color'} = '#FF8800';
    } elsif ($data->{'tSeverity'} =~ /\bHigh\b/) {
      $attach->{'color'} = '#ff4444';
    } elsif ($data->{'tSeverity'} =~ /\bDisaster\b/) {
      $attach->{'color'} = '#CC0000';
    } else {
      $attach->{'color'} = '#2BBBAD';
    }

    # if its ok overide the color
    if ($data->{'tStatus'} eq "OK") {
        $attach->{'color'} = '#00C851';
    }

    # build the payload objects
    my $attachment->{'attachments'}[0] = $attach;
    $attach = $attachment;

  } else {
    # send simple payload
    my $text = "$data->{'hostname'}  $data->{'tName'} $data->{'tStatus'}";
    $attach->{'text'} = $text;
  }

  # attach the core required stuff to send it
  $attach->{'icon_url'} = $iconUrl;
  $attach->{'username'} = $botName;
  $attach->{'channel'} = $channel;

  if ($debug) {
    my $body = Dumper $attach;
    print $logFH "object:\n$body\n";
  }

    # encode the json
  my $jsonBody = encode_json $attach;

  # setup the payload
  my $jsonPayload = qq(payload=$jsonBody);

  return $jsonPayload;
}


sub processInternal {
  my $data = shift;
  my $attach = ();

  # calculate the type of internal message
  my $isItem=0;
  my $isLLD=0;
  my $isTrigger=0;
  if ($data->{'state'} ne "{ITEM.STATE}") {
    $isItem = 1;
  }
  if ($data->{'lldState'} ne "{LLDRULE.STATE}") {
    $isLLD = 1;
  }
  if ($data->{'tState'} ne "{TRIGGER.STATE}") {
    $isTrigger = 1;
  }

  # generate the strings
  if ($isItem) {
    # items
    my $text = "$data->{'hostname'} $data->{'item'} $data->{'state'}";
    $attach->{'text'} = $text;
  } elsif ($isLLD) {
    # lld
    my $text = "$data->{'hostname'} $data->{'lldRule'} $data->{'lldState'}";
    $attach->{'text'} = $text;
  } elsif ($isTrigger) {
    # triggers
    my $text = "$data->{'hostname'} $data->{'tName'} $data->{'tState'}";
    $attach->{'text'} = $text;
  }

  # attach the core required stuff to send it
  $attach->{'icon_url'} = $iconUrl;
  $attach->{'username'} = $botName;
  $attach->{'channel'} = $channel;

  if ($debug) {
    my $body = Dumper $attach;
    print $logFH "object:\n$body\n";
  }

    # encode the json
  my $jsonBody = encode_json $attach;

  # setup the payload
  my $jsonPayload = qq(payload=$jsonBody);

  return $jsonPayload;
}
