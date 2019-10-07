#!/usr/bin/perl
#!C:\Strawberry\perl\bin\perl.exe

################################################################################
# add a issued cooldown
################################################################################

################################################################################
# load modules
################################################################################
use strict;
use warnings;
use DBI;
use Cwd;
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Data::Dumper;

use lib getcwd() . "/../../../data/lib/perl5";
use DbTools;
use SteamAPI;

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# create the cgi 
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
my $cgi = new CGI;

################################################################################
# Main subroutine
################################################################################
sub Main() {

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # var declaration
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $query = undef;
  my $old_cooldown_time = 0;
  my $old_cooldown_reason = '';

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # create the database handle
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $dbfile = getcwd() . "/../../../data/database.db";
  my $dbh    = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "") or die 
    "Failed to open database";

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # get values passed to this handler
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $steam_id64            = $cgi->param('steam_id64');
  my $steam_cooldown_reason = $cgi->param('steam_cooldownreason');
  my $steam_cooldown_time   = $cgi->param('steam_cooldowntime');

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # check values passed to this handler
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  unless ($steam_id64 =~ m/[0-9]/) {
    return(1) if _error("Steam 64 ID must be int");
  }

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # get values from steam api and timestamp
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $steam_avatar_url = SteamAPI::GetUserAvatarUrl($steam_id64);
  my $steam_profile_name = SteamAPI::GetUserProfileName($steam_id64);
  my $steam_profile_visibility = SteamAPI::GetUserProfileVisibility($steam_id64);
  my $steam_last_modified = localtime(time());

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # write to database
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  if (DbTools::CheckDoubleSteamID($dbh, $steam_id64, 'cooldowns')) {

    # get old cooldown time and add the new time on top of that
    $query = "
      SELECT steam_cooldown_time FROM cooldowns WHERE steam_id64 = '$steam_id64';
    ";
    $query = $dbh->prepare($query);
    $query->execute();
    while (my @row = $query->fetchrow_array()) {
      $old_cooldown_time = join(", ", @row);
    }
    my $new_cooldown_time = $old_cooldown_time + $steam_cooldown_time;

    # get old cooldown reasons and add new ones on top of that
    $query = "
      SELECT steam_cooldown_reason FROM cooldowns WHERE steam_id64 = '$steam_id64';
    ";
    $query = $dbh->prepare($query);
    $query->execute();
    while (my @row = $query->fetchrow_array()) {
      $old_cooldown_reason = join(", ", @row);
    }
    my $new_cooldown_reason = $old_cooldown_reason . "</br>" . $steam_cooldown_reason;

    # update the cooldowns table
    $query = "
      UPDATE cooldowns
      SET steam_username = '$steam_profile_name',
      steam_cooldown_time = '$new_cooldown_time',
      steam_cooldown_reason = '$new_cooldown_reason',
      steam_avatar_url = '$steam_avatar_url',
      steam_profile_visibility = '$steam_profile_visibility',
      steam_last_modified = '$steam_last_modified'
      ;
    ";
    $query = $dbh->prepare($query);
    $query->execute();

    # increment statistics
    DbTools::IncrementStatistics($dbfile, 'cooldown_type_' . $steam_cooldown_time);
    DbTools::IncrementStatistics($dbfile, 'cooldown_reason_' . $steam_cooldown_reason);
    DbTools::IncrementStatistics($dbfile, 'cooldown_time_total', $steam_cooldown_time);

  } else {
    
    # add a new victim to the cooldowns table
    $query = "
      INSERT INTO cooldowns(
        steam_id64, 
        steam_username, 
        steam_cooldown_time, 
        steam_cooldown_reason, 
        steam_avatar_url,
        steam_profile_visibility,
        steam_last_modified
      ) VALUES (
        '$steam_id64',
        '$steam_profile_name',
        '$steam_cooldown_time',
        '$steam_cooldown_reason',
        '$steam_avatar_url',
        '$steam_profile_visibility',
        '$steam_last_modified'
      );
    ";
    $query = $dbh->prepare($query);
    $query->execute();

    # increment statistics
    DbTools::IncrementStatistics($dbfile, 'cooldown_type_' . $steam_cooldown_time);
    DbTools::IncrementStatistics($dbfile, 'cooldown_users_total');
    DbTools::IncrementStatistics($dbfile, 'cooldown_reason_' . $steam_cooldown_reason);
    DbTools::IncrementStatistics($dbfile, 'cooldown_time_total', $steam_cooldown_time);

  }
  
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # return an exit code and do some cleanup
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  $dbh->disconnect();
  $query = undef;
  return(0);

}

################################################################################
# _error subroutine
################################################################################
sub _error {

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # get vars passed to function
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $msg = shift;

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # print the cgi error
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print "Content-Type: text/html\n\n";
  print "<h1>ERROR:</h1>\n";
  print "<p>$msg</p>\n";

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # return true because we had an error
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  return(1);

}

################################################################################
# Main subroutine call and redirect
################################################################################
Main();
print $cgi->redirect(
  -url => '../scripts/list-items.cgi',
);
