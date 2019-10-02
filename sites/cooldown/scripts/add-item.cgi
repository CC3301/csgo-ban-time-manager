#!perl

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

# make the database handle, for now sqlite3
my $dbfile = "../../data/database.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

my $exec = "
CREATE TABLE cooldowns(
  steam_username VARCHAR,
  steam_id64 INTEGER,
  steam_avatar_url VARCHAR,
  UNIQUE(steam_id64)
)
";
#$exec = $dbh->prepare($exec);
#$exec->execute();

# start the html/cgi part
my $query = new CGI;
print $query->header();
print $query->start_html();

# for now just print the data, validate later and also add to DB later
my $steam_username = $query->param('steam_username');
my $steam_id64 = $query->param('steam_id64');

# check if default values are submitted and exit and throw error
unless (defined $steam_id64 && defined $steam_username) {
  print "ERROR: No values submitted\n";
  exit();
}
if ($steam_username eq "Steam Username" || $steam_id64 == 123456789) {
  print "ERROR: Default values submitted\n";
  exit();
}

# add to database
$exec = $dbh->prepare(qq(INSERT INTO cooldowns(steam_username, steam_id64, steam_avatar_url) VALUES ('$steam_username', '$steam_id64', 'test');));
$exec->execute();

# print success and redirect to other page
print "SUCCESS: Added user '$steam_username' to the database.\n";
print $query->end_html();