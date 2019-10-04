#!C:\Strawberry\perl\bin\perl.exe
#!/usr/bin/perl

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
  my %steam_ban_state = SteamAPI::GetUserBanState($steam_id64);
  my $steam_last_modified = localtime(time());

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # write to database
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  if (DbTools::CheckDoubleSteamID($dbh, $steam_id64, 'vacs')) {

    # update the cooldowns table
    $query = "
      UPDATE vacs
      SET steam_username = '$steam_profile_name',
      steam_ban_vac = '$steam_ban_state{vac}',
      steam_ban_game = '$steam_ban_state{game}',
      steam_ban_trade = '$steam_ban_state{trade}',
      steam_ban_community = '$steam_ban_state{community}',
      steam_avatar_url = '$steam_avatar_url',
      steam_profile_visibility = '$steam_profile_visibility',
      steam_last_modified = '$steam_last_modified'
      ;
    ";
    $query = $dbh->prepare($query);
    $query->execute();

  } else {
    
    # add a new victim to the cooldowns table
    $query = "
      INSERT INTO vacs(
        steam_id64,
        steam_username,
        steam_ban_vac,
        steam_ban_game,
        steam_ban_trade,
        steam_ban_community,
        steam_avatar_url,
        steam_profile_visibility,
        steam_last_modified
      ) VALUES (
        '$steam_id64',
        '$steam_profile_name',
        '$steam_ban_state{vac}',
        '$steam_ban_state{game}',
        '$steam_ban_state{trade}',
        '$steam_ban_state{community}',
        '$steam_avatar_url',
        '$steam_profile_visibility',
        '$steam_last_modified'
      );
    ";
    $query = $dbh->prepare($query);
    $query->execute();

    # increment statistics
    if ($steam_ban_state{vac}) {
      DbTools::IncrementStatistics($dbfile, 'ban_vac');
    } elsif ($steam_ban_state{game}) {
      DbTools::IncrementStatistics($dbfile, 'ban_game');
    } elsif ($steam_ban_state{trade}) {
      DbTools::IncrementStatistics($dbfile, 'ban_trade');
    } elsif ($steam_ban_state{community}) {
      DbTools::IncrementStatistics($dbfile, 'ban_community');
    }

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
  print $cgi->header();
  print $cgi->start_html();
  print "<h1>ERROR:</h1>\n";
  print "<p>$msg</p>\n";
  print $cgi->end_html();

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
  -url => '../scripts/list-suspects.cgi',
);