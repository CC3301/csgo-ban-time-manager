#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use Data::Dumper;
use CGI;

use lib getcwd() . "/lib/perl5/";
use SteamAPI;

my $cgi = new CGI;

print $cgi->header();
print Dumper(SteamAPI::GetUserAvatarUrl('76561197988082368'));
