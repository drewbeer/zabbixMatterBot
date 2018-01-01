#!/usr/bin/perl
# https://github.com/drewbeer/zabbix-mattermost-alertscript DrewBeer
# passes data in and curls it out via json to mattermost webhooks as attachments.
# you can use this as you wish, free as in beer, life is that way.
# minify your json before you set it in zabbix, it will make your life easier

use warnings;
use strict;
use JSON;
use Data::Dumper;
use feature qw(switch say);
no if $] >= 5.018, warnings => "experimental::smartmatch";

# turn on file logging to /tmp/zabbix-mattermost.log
my $debug = 0;
my $logFH;
my $messageData = ();

# debug log the incoming data
if ($debug) {
  open($logFH, '>>', '/tmp/zabbix-mattermost.log');
  my $dump = Dumper(@ARGV);
  print $logFH "args:\n$dump\n";
}

# get arguments
$messageData->{'sendTo'} = shift @ARGV or die "Invalid number of arguments\n";
$messageData->{'webhook'} = shift @ARGV;
$messageData->{'name'} = shift @ARGV;
$messageData->{'iconURL'} = shift @ARGV;

# get the body, and decode the json
my $body = shift @ARGV;

my $decoded_body = decode_json $body;
$messageData->{'payload'}->{'attachments'}[0] = $decoded_body;
my $color = getColor($decoded_body->{'pretext'});

# add core details
$messageData->{'payload'}->{'icon_url'} = $messageData->{'iconURL'};
$messageData->{'payload'}->{'username'} = $messageData->{'name'};
$messageData->{'payload'}->{'channel'} = $messageData->{'sendTo'};

# insert the color
$messageData->{'payload'}->{'attachments'}[0]->{'color'} = $color;

# debug again if needed
if ($debug) {
  my $dump = Dumper($messageData);
  print $logFH "payload:\n$dump\n";
}

# encode the json
my $jsonBody = encode_json $messageData->{'payload'};

# setup the payload
my $payload = qq(payload=$jsonBody);

# final debug
if ($debug) {
  print $logFH "final payload:\n$payload\n";
}

# send the payload
sendPayload($payload);
exit;

# send the payload
sub sendPayload {
  my($payload) = @_;
  my $cmd = qq( curl -s -i -X POST --data-urlencode '$payload' $messageData->{'webhook'} > /dev/null);
  `$cmd`;

  # final debug
  if ($debug) {
    print $logFH "curl:\n$cmd\n";
  }
}

# parse the message for color really, no reason to parse for the severity that i can see
sub getColor {
  my $message = shift;
  my $result = ();

  if ($debug) {
    print $logFH "color-type:\$message\n";
  }

  given ($message) {
    when ($message =~ /\bOK\b/) {
      $result->{'color'} = '#00C851';
    }
    when ($message =~ /\bNot classified\b/) {
      $result->{'color'} = '#33b5e5';
    }
    when ($message =~ /\bInformation\b/) {
      $result->{'color'} = '#0099CC';
    }
    when ($message =~ /\bWarning\b/) {
      $result->{'color'} = '#ffbb33';
    }
    when ($message =~ /\bAverage\b/) {
      $result->{'color'} = '#FF8800';
    }
    when ($message =~ /\bHigh\b/) {
      $result->{'color'} = '#ff4444';
    }
    when ($message =~ /\bDisaster\b/) {
      $result->{'color'} = '#CC0000';
    }
    default {
      $result->{'color'} = '#2BBBAD';
    }
  }
  return $result->{'color'};
}
