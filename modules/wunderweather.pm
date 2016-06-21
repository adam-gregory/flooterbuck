#------------------------------------------------------------------------
# WunderGround Weather module.
#
# Tradotto@gmail.com (C) 2016-- get the weather forcast From wunderground.
# feel free to use, copy, cut up, and modify, but if
# you do something cool with it, let me know.
#
# $Id: wunderweather.pm,v .1 2016/06/21 20:58:03 Tradotto@gmail.com Exp $
#------------------------------------------------------------------------
package wunderweather;

my $no_weather;
my $default = 'KAGC';
my $api_key = 'PUT YOUR KEY HERE';

BEGIN {
    eval "use LWP::UserAgent";
    eval "use JSON";
    $no_weather++ if ($@);
}

sub get_weather {
	my ($station) = shift;
	my $result;
	# make this work like Aviation
	$station = uc($station);

	my $station = uc($2);
	$station =~ s/[.?!]$//;
	$station =~ s/\s+$//g;
	return "'$station' doesn't look like a valid ICAO airport identifier."
	unless $station =~ /^[\w\d]{3,4}$/;
	$station = "C" . $station
	if length($station) == 3 && $station =~ /^Y/;
	$station = "K" . $station if length($station) == 3;

	my $ua = new LWP::UserAgent;
	if ( my $proxy = main::getparam('httpproxy') ) {
	    $ua->proxy( 'http', $proxy );
	}

	$ua->timeout(10);
	my $request = new HTTP::Request( 'GET',
	    "http://api.wunderground.com/api/$api_key/conditions/q/$station.json" );
	print($request->uri);	
	my $response = $ua->request($request);

	if ( !$response->is_success ) {
	    return "Something failed in connecting to the NOAA web server. Try again later.";
	}

	$content = $response->content;

	if ( $content =~ /ERROR/i ) {
	    return "I can't find that station code (see http://weather.noaa.gov/weather/curcond.html for locations codes)";
	}
	$content = JSON->new->utf8->decode($content);
	$result .= "Current conditions for $station";
	$result .= "\n" . $content->{'current_observation'}{'temperature_string'};
	$result .= " winds ". $content->{'current_observation'}{'wind_string'};
	$result .= " and a relative humidity of " . $content->{'current_observation'}{'relative_humidity'};
	return $result;
}


sub scan (&$$) {
    my ( $callback, $message, $who ) = @_;

    if ( ::getparam('wunderweather')
        and
        ( $message =~ /^\s*(ww|wunderweather)\s+(?:for\s+)?(.*?)\s*\?*\s*$/ )
      )
    {
        my $code = $2;
        $callback->( get_weather($code) );
        return 'NOREPLY';
    }
    return undef;
}

"wunderweather";

__END__

=head1 NAME

wunderweather.pm - Get the weather from a wunderground server

=head1 PREREQUISITES

	LWP::UserAgent
	JSON

=head1 PARAMETERS

wunderweather

=head1 PUBLIC INTERFACE

	wunderweather [for] <station>

=head1 DESCRIPTION

Contacts C<WunderGround> and gets the weather report for a given
station.

=head1 AUTHORS

Tradotto@gmail.com
