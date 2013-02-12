use strict;
#
# Irssi Pastebin
#
# Copyright (C) 2010 Samuel Vandamme
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Change Log:
# v1.0b:
#        - Initial release
# v1.0:
#        - Looks stable
#
# Requirements:
#        - perl-libwww
#
# Problems ?
#        http://github.com/kidk/irssi-pastebin/issues
#        OR
#        email : samuel@sava.be

use vars qw($VERSION %IRSSI);
$VERSION = "1.0";
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
			"api_dev_key" => "0ab63310e602442c43ae1753955aa345",
			"api_option" => "paste",
			"api_paste_code" => $code,
		);

		# Pastebin
		my $browser = new LWP::UserAgent;
		my $page = $browser->post("http://pastebin.com/api/api_post.php", \%fields);
		
		if ($page->is_success)
		{
			$server->command('MSG -- '.$channel.' '.$page->decoded_content);
		}
		else
		{
			$server->command('MSG -- '.$channel.' pastebin upload failed');
		}
		
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
