#!perl

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use JSON;
use LWP::Simple;
use Data::Dumper;

# make the database handle, for now sqlite3
my $dbfile = "../../../data/cooldowns.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

# steam api key
open(my $fh, '<<', "data/api_key.txt") or die "Failed to read steam api key";
  my $steam_api_key = <$fh>;
close $fh; 

# init db
my $exec = "
CREATE TABLE cooldowns(
  steam_username VARCHAR,
  steam_id64 INTEGER,
  steam_avatar_url VARCHAR,
  steam_cooldowntime INTEGER,
  steam_cooldownreason VARCHAR,
  UNIQUE(steam_id64)
)
";
#$exec = $dbh->prepare($exec);
#$exec->execute();
#exit();

# start the html/cgi part
my $query = new CGI;

# for now just print the data, validate later and also add to DB later
my $steam_id64 = $query->param('steam_id64');
my $steam_cooldowntime = $query->param('steam_cooldowntime');
my $steam_cooldownreason = $query->param('steam_cooldownreason');

# check if we have appropiate values 
unless (defined $steam_id64 && defined $steam_cooldowntime && defined $steam_cooldownreason) {
  _error("Incomplete dataset");
}
if ($steam_id64 eq '' || $steam_cooldowntime eq '' || $steam_cooldownreason eq '') {
  _error("Incomplete dataset");
}
unless ($steam_id64 =~ m/[0-9]/) {
  _error("Steam 64 ID must be int");
}
unless ($steam_cooldowntime =~ m/[0-9]/) {
  _error("cooldowntime must be int");
}

# get the steam avatar url and display username
my $steam_api_response = get("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$steam_api_key&steamids=$steam_id64");
$steam_api_response = decode_json($steam_api_response);
my $steam_avatar_url = $steam_api_response->{response}->{players}[0]->{avatarmedium};
my $steam_username   = $steam_api_response->{response}->{players}[0]->{personaname};

# add to database
$exec = $dbh->prepare(qq(INSERT INTO cooldowns(steam_username, steam_id64, steam_avatar_url, steam_cooldowntime, steam_cooldownreason) VALUES ('$steam_username', '$steam_id64', '$steam_avatar_url', '$steam_cooldowntime', '$steam_cooldownreason');));
$exec->execute();

# print success and redirect to other page
print $query->redirect(
  -url => "../../../index.html",
);


# error subroutine
sub _error {
  my $msg = shift;
  print $query->header();
  print $query->start_html();
  print $msg;
  print $query->end_html();
  exit();
}