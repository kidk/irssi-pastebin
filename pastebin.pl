use strict;
#
# Irssi Pastebin
# Copyright (C) Samuel Vandamme
#

#
# Check README for license
#

use vars qw($VERSION %IRSSI);
$VERSION = "1.0b";
%IRSSI = (
	authors 	=>	"Samuel 'kidk' Vandamme",
	contact		=> 	"samuel\@sava.be",
	name		=>	"pastebin",
	description	=>	"Automatically catche large paste's, add them to pastebin and return the url.",
	license		=>	"",
	url		=>	"",
	changed		=>	"",
	modules		=>	"",
	commands	=>	""
);

use Irssi;
use LWP::UserAgent;
use HTTP::Request::Common;
use vars qw($timer $channel $server @log);

sub microtime {
	my ($secs, $microsecs) = gettimeofday();
	
        return $secs + ($microsecs * 1e-6);
}




sub sig_send_text ($$$) {
	my ($line, $lserver, $witem) = @_;
	$channel = $witem->{name};
	$server = $lserver;

	# Checks
	return unless (ref $server);
	return unless ($witem && ($witem->{type} eq 'CHANNEL' || $witem->{type} eq 'QUERY'));
	if ( !@log ) {
		@log = ();
	}

	# Time check
	Irssi::timeout_remove($timer);
	$timer = Irssi::timeout_add(10, \&pastebin, undef);

	# Add message to log
	push(@log, $line);

	Irssi::signal_stop();			
}

sub pastebin {
	my $size = @log;

	
	if ( $size >= Irssi::settings_get_int('pastebin_lines') ) {
		# Prepare message
		my $code = join("\n", @log);
		my %fields = (
			"parent_pid" => "",
			"format" => "text",
			"poster" => "",
			"paste" => "Send",
			"code2"	=> $code,
			"expiry"=> "d"
		);

		# Pastebin
		my $browser = new LWP::UserAgent;
		my $page = $browser->post("http://pastebin.com/pastebin.php", \%fields);
		$server->command('MSG -- '.$channel.' '.$page->header('Location'));
	} else	{
		# Output normally
		foreach (@log) { 
			$server->command('MSG -- '.$channel.' '.$_);
		}
	}

	# Clean
	@log = ();
	Irssi::timeout_remove($timer);
}

Irssi::settings_add_int($IRSSI{name}, 'pastebin_lines', 5);
Irssi::signal_add('send text', 'sig_send_text');

print CLIENTCRAP "%B>>%n ".$IRSSI{name}." ".$VERSION." loaded";
