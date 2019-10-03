#!C:\Strawberry\perl\bin\perl.exe

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use DBI;
use JSON;
use LWP::Simple;
use Data::Dumper;

# make the database handle, for now sqlite3
my $dbfile = "cooldowns.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
my $exec = undef;

# check for init and init the database
if ($ARGV[0] eq 'init') {
  $exec = "
  CREATE TABLE cooldowns(
    steam_username VARCHAR,
    steam_id64 INTEGER,
    steam_avatar_url VARCHAR,
    steam_cooldowntime INTEGER,
    steam_cooldownreason VARCHAR,
    steam_profile_visibility VARCHAR,
    UNIQUE(steam_id64)
  )
  ";
  $exec = $dbh->prepare($exec);
  $exec->execute();
  exit();
}

# steam api key
open(my $fh, '<', "../../../data/api_key.txt") or die "Failed to read steam api key: $!";
  my $steam_api_key = <$fh>;
close $fh; 

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
my $steam_profile_visibility = $steam_api_response->{response}->{players}[0]->{communityvisibilitystate};

# define communityvisibilitystates
my %communityvisibilitystates = (
  1 => 'Private',
  2 => 'Friends Only',
  3 => 'Public',
);
$steam_profile_visibility = $communityvisibilitystates{$steam_profile_visibility};


# check if we have a entry with the same steam_id64
$exec = "
  SELECT steam_id64 FROM cooldowns WHERE steam_id64 = $steam_id64;
";
$exec = $dbh->prepare($exec);
$exec->execute();

# get id if there is a matching one
my @ids = ();
while (my @row = $exec->fetchrow_array){
  push @ids, join(", ", @row);
}

# check for if the id already exists
if ($steam_id64 == $ids[0]) {

  # read old cooldowntime
  my @cooldowntime = ();
  $exec = "
    SELECT steam_cooldowntime FROM cooldowns WHERE steam_id64 = $steam_id64;
  ";
  $exec = $dbh->prepare($exec);
  $exec->execute();


  while (my @row = $exec->fetchrow_array) {
    push @cooldowntime, join (", ", @row);
  }
  $steam_cooldowntime = $steam_cooldowntime + $cooldowntime[0];

  # read old reasons
  my @cooldownreasons = ();
  $exec = "
    SELECT steam_cooldownreason FROM cooldowns WHERE steam_id64 = $steam_id64;
  ";
  $exec = $dbh->prepare($exec);
  $exec->execute();

  while (my @row = $exec->fetchrow_array) {
    push @cooldownreasons, join (", ", @row);
  }
  $steam_cooldownreason = $steam_cooldownreason . "</br>$cooldownreasons[0]";

  # write updated data
  $exec = "
    UPDATE cooldowns SET steam_cooldowntime = '$steam_cooldowntime', steam_avatar_url = '$steam_avatar_url', steam_username = '$steam_username', steam_profile_visibility = '$steam_profile_visibility', steam_cooldownreason = '$steam_cooldownreason' WHERE steam_id64 = '$steam_id64';
  ";
  $exec = $dbh->prepare($exec);
  $exec->execute();

} else {

  # we dont have the id, so we add a new victim, thus all the data needs to be saved
  $exec = "
    INSERT INTO cooldowns(steam_username, steam_id64, steam_avatar_url, steam_cooldowntime, steam_cooldownreason, steam_profile_visibility) VALUES ('$steam_username', '$steam_id64', '$steam_avatar_url', '$steam_cooldowntime', '$steam_cooldownreason', '$steam_profile_visibility');
  ";
  $exec = $dbh->prepare($exec);
  $exec->execute();
}

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